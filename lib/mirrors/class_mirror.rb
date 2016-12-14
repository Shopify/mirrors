module Mirrors
  # A specific mirror for a class, that includes all the capabilites
  # and information we can gather about classes.
  #
  # @!attribute [rw] singleton_instance
  #   @return [Mirror,nil] if a singleton class, the corresponding
  #     instance.
  class ClassMirror < ObjectMirror
    # We are careful to not call methods directly on +@reflectee+ here, since
    # people really like to override weird methods on their classes. Instead we
    # borrow the methods from +Module+, +Kernel+, or +Class+ directly and bind
    # them to the reflectee.
    #
    # We don't need to be nearly as careful about this with +Method+ or
    # +UnboundMethod+ objects, since their +@reflectee+s are two core classes,
    # not an arbitrary user class.

    attr_accessor :singleton_instance

    def initialize(obj)
      super(obj)
      @field_mirrors = {}
      @method_mirrors = {}
    end

    # @return [Boolean] Is this a Class, as opposed to a Module?
    def class?
      reflectee_is_a?(Class)
    end

    # Find the package for this class/module from a line in the docstring
    # before some location where the class is opened of the form
    # +# @package foo+.
    #
    # @todo continue recursing even when a match is found and conflict if
    #   multiple packages are specified.
    # @todo if conflicting packages are specified at different definition
    #   sites, fail.
    #
    # @return [String,nil] package name, if any.
    def stripe_proposal_package
      nesting.each do |cm|
        next unless ranges = Mirrors::Init.definition_ranges(cm.name)
        ranges.each do |file, startline, _|
          if pkg = tag_for_block("@package", file, startline)
            return pkg
          end
        end
      end
      nil
    end

    # Test whether this class or module is private to the package it was
    # defined in. If not in a package, this return false. If in a package, but
    # lacking an +@export+ comment, return false. If an +@export+ comment is
    # given, it must match the name of the class. If the class is the toplevel
    # of the package, it is exported by default.
    #
    # @example
    #   # @package my-package
    #   class Foo
    #     # @export Bar
    #     class Bar
    #     end
    #     class Baz
    #     end
    #   end
    #   Mirrors.reflect(Foo).stripe_proposal_private? # => false
    #   Mirrors.reflect(Foo::Bar).stripe_proposal_private? # => false
    #   Mirrors.reflect(Foo::Baz).stripe_proposal_private? # => true
    #
    # @todo verify the name specified in the export comment
    #
    # @return [String,nil] package name, if any.
    def stripe_proposal_private?
      pkg = stripe_proposal_package
      return false unless pkg

      ranges = Mirrors::Init.definition_ranges(name)
      return true unless ranges # true? false? what makes more sense?

      ranges.each do |file, startline, _|
        return false if tag_for_block("@package", file, startline)
        return false if tag_for_block("@export", file, startline)
      end

      true
    end

    # @return [PackageMirror] the "package" into which this class/module has
    #   been sorted.
    def package
      @package ||= PackageInference.infer_from(self)
    end

    # The source files this class is defined and/or extended in.
    #
    # @return [Array<FileMirror>]
    def source_files
      instance_methods.map(&:file).compact.uniq
    end

    # @return [Boolean] Is the reflectee is a singleton class?
    def singleton_class?
      n = name
      # #<Class:0x1234deadbeefcafe> is an anonymous class.
      # #<Class:A> is the singleton class of A
      # #<Class:#<Class:0x1234deadbeefcafe>> is the singleton class of an
      #   anonymous class
      n.match(/^\#<Class:.*>$/) && !n.match(/^\#<Class:0x\h+>$/)
    end

    # @return [Boolean] Is this an anonymous class or module?
    def anonymous?
      name.match(/^\#<(Class|Module):0x\h+>$/)
    end

    # @!group Instance Methods: Fields

    # The constants defined within this class. This includes nested
    # classes and modules, but also all other kinds of constants.
    #
    # @return [Array<FieldMirror>]
    def constants
      field_mirrors(reflectee_send_from_module(:constants))
    end

    # Searches for the named constant in the mirrored namespace. May
    # include a colon (::) separated constant path.
    #
    # @return [ClassMirror, nil] the requested constant, or nil
    def constant(str)
      path = str.to_s.split('::')
      c = path[0..-2].inject(@reflectee) do |klass, s|
        Mirrors.rebind(Module, klass, :const_get).call(s)
      end

      owner = c || @reflectee
      # NameError if constant doesn't exist.
      Mirrors.rebind(Module, owner, :const_get).call(path.last)
      field_mirror(owner, path.last)
    rescue NameError
      nil
    end

    # All constants, class vars, and class instance vars.
    # @return [Array<FieldMirror>]
    def fields
      [constants, class_variables, class_instance_variables].flatten
    end

    # The known class variables.
    # @return [Array<FieldMirror>]
    def class_variables
      field_mirrors(reflectee_send_from_module(:class_variables))
    end

    # The known class instance variables.
    # @return [Array<FieldMirror>]
    def class_instance_variables
      field_mirrors(reflectee_send_from_module(:instance_variables))
    end

    # @!endgroup (Fields)
    # @!group Instance Methods: Methods

    # @return [Array<MethodMirror>] The instance methods of this class.
    def class_methods
      singleton_class.instance_methods
    end

    # The instance methods of this class. To get to the class methods,
    # ask the #singleton_class for its methods.
    #
    # @return [Array<MethodMirror>]
    def instance_methods
      mirrors(all_instance_methods(@reflectee))
    end

    # The instance method of this class or any of its superclasses
    # that has the specified name
    #
    # @param [Symbol] name of the method to look up
    # @return [MethodMirror, nil] the method or nil, if none was found
    # @raise [NameError] if the module isn't present
    def instance_method(name)
      Mirrors.reflect(reflectee_send_from_module(:instance_method, name))
    end

    # The singleton/static method of this class or any of its superclasses
    # that has the specified name
    #
    # @param [Symbol] name of the method to look up
    # @return [MethodMirror, nil] the method or nil, if none was found
    # @raise [NameError] if the module isn't present
    def class_method(name)
      singleton_class.instance_method(name)
    end

    # This will probably prevent confusion
    alias_method :__methods, :methods
    undef methods
    alias_method :__method, :method
    undef method

    # @!endgroup (Methods)

    # @!group Instance Methods: Related Classes

    # @return [Array<ClassMirror>] The mixins included in the ancestors of this
    #   class.
    def mixins
      mirrors(reflectee_send_from_module(:ancestors).reject { |m| m.is_a?(Class) })
    end

    # @return [Array<ClassMirror>] The full module nesting.
    def nesting
      ary = []
      reflectee_send_from_module(:name).split('::').inject(Object) do |klass, str|
        ary << Mirrors.rebind(Module, klass, :const_get).call(str)
        ary.last
      end
      ary.reverse.map { |n| Mirrors.reflect(n) }
    rescue NameError
      [self]
    end

    # @return [Array<ClassMirror>] The classes nested within the reflectee.
    def nested_classes
      nc = reflectee_send_from_module(:constants).map do |c|
        # do not trigger autoloads
        if reflectee_send_from_module(:const_defined?, c) && !reflectee_send_from_module(:autoload?, c)
          reflectee_send_from_module(:const_get, c)
        end
      end

      consts = nc.compact.select do |c|
        Mirrors.rebind(Kernel, c, :is_a?).call(Module)
      end

      mirrors(consts.sort_by { |c| Mirrors.rebind(Module, c, :name).call })
    end

    # @return [ClassMirror] The direct superclass
    def superclass
      Mirrors.reflect(reflectee_superclass)
    end

    # @return [Array<ClassMirror>] The known subclasses
    def subclasses
      mirrors(ObjectSpace.each_object(Class).select { |a| a.superclass == @reflectee })
    end

    # @return [Array<ClassMirror>] The list of ancestors
    def ancestors
      mirrors(reflectee_send_from_module(:ancestors))
    end

    # @!endgroup (Related Classes)

    # What is the primary defining file for this class/module?
    # This is necessarily best-effort but it will be right in simple cases.
    #
    # @return [String, nil] the path on disk to the file, if determinable.
    def file(resolver = PackageInference::ClassToFileResolver.new)
      f = resolver.resolve(self)
      f ? Mirrors.reflect(FileMirror::File.new(f)) : nil
    end

    # @example
    #   Mirrors.reflect(A::B).name #=> "A::B"
    #   Mirrors.reflect(Module.new).name #=> "#<Module:0x007fd22902d9d0>"
    # @return [String] the default +#inspect+ of this class
    def name
      # +name+ itself is blank for anonymous/singleton classes
      @name ||= reflectee_send_from_module(:inspect)
    end

    # @return [String] the last component in the module nesting of the name.
    # @example
    #   Mirrors.reflect(A::B::C).demodulized_name #=> "C"
    def demodulized_name
      name.split('::').last
    end

    # Cache a {MethodMirror} related to this {ClassMirror} in order to prevent
    # generating garbage each time methods are returned. Idempotent.
    #
    # @param [MethodMirror] mirror the mirror to be interned
    # @return [MethodMirror] the interned mirror. If already interned, the
    #   previous version.
    def intern_method_mirror(mirror)
      @method_mirrors[mirror.name] ||= mirror
    end

    # Cache a {FieldMirror} related to this {ClassMirror} in order to prevent
    # generating garbage each time fields are returned. Idempotent.
    #
    # @param [FieldMirror] mirror the mirror to be interned
    # @return [FieldMirror] the interned mirror. If already interned, the
    #   previous version.
    def intern_field_mirror(mirror)
      @field_mirrors[mirror.name] ||= mirror
    end

    private

    # This one is not defined on Module since it only applies to classes
    def reflectee_superclass
      Mirrors.rebind(Class.singleton_class, @reflectee, :superclass).call
    end

    def reflectee_send_from_module(message, *args)
      Mirrors.rebind(Module, @reflectee, message).call(*args)
    end

    def all_instance_methods(mod)
      pub_prot_names = Mirrors.rebind(Module, mod, :instance_methods).call(false)
      priv_names = Mirrors.rebind(Module, mod, :private_instance_methods).call(false)

      (pub_prot_names.sort + priv_names.sort).map do |n|
        Mirrors.rebind(Module, mod, :instance_method).call(n)
      end
    end

    # This could obviously be done way less stupidly.
    def tag_for_block(tag, file, startline)
      lines = File.readlines(file)
      lines[0...startline - 1].reverse.detect do |line|
        break unless line =~ /^\s*#/
        if md = line.match(/# #{tag} (\S+)/)
          return md[1]
        end
      end
      nil
    end
  end
end
