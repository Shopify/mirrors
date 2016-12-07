module Mirrors
  # A specific mirror for a class, that includes all the capabilites
  # and information we can gather about classes.
  #
  # We are careful to not call methods directly on +@subject+ here, since
  # people really like to override weird methods on their classes. Instead we
  # borrow the methods from +Module+, +Kernel+, or +Class+ directly and bind
  # them to the subject.
  #
  # We don't need to be nearly as careful about this with +Method+ or
  # +UnboundMethod+ objects, since they consist of two core classes, not an
  # arbitrary user class.
  class ClassMirror < ObjectMirror
    def initialize(obj)
      super(obj)
      @field_mirrors = {}
      @method_mirrors = {}
    end

    # What is the primary defining file for this class/module?
    # This is necessarily best-effort but it will be right in simple cases.
    #
    # @return [String, nil] the path on disk to the file, if determinable.
    def file
      Mirrors::PackageInference::ClassToFileResolver.new.resolve(@subject)
    end

    def is_class # rubocop:disable Style/PredicateName
      subject_send_from_kernel(:is_a?, Class)
    end

    def package
      # TODO(burke)
    end

    def fields
      [constants, class_variables, class_instance_variables, instance_variables].flatten
    end

    # The known class variables.
    # @see #instance_variables
    # @return [Array<FieldMirror>]
    def class_variables
      field_mirrors(subject_send_from_module(:class_variables))
    end

    # The known class variables.
    # @see #instance_variables
    # @return [Array<FieldMirror>]
    def class_instance_variables
      field_mirrors(subject_send_from_module(:instance_variables))
    end

    # The source files this class is defined and/or extended in.
    #
    # @return [Array<String,File>]
    def source_files
      locations = subject_send_from_module(:instance_methods, false).collect do |name|
        method = subject_send_from_module(:instance_method, name)
        sl = method.source_location
        sl.first if sl
      end
      locations.compact.uniq
    end

    # The singleton class of this class
    #
    # @return [ClassMirror]
    def singleton_class
      Mirrors.reflect(subject_send_from_kernel(:singleton_class))
    end

    # Predicate to determine whether the subject is a singleton class
    #
    # @return [true,false]
    def singleton_class?
      name.match(/^\#<Class:.*>$/)
    end

    # The mixins included in the ancestors of this class.
    #
    # @return [Array<ClassMirror>]
    def mixins
      mirrors(subject_send_from_module(:ancestors).reject { |m| m.is_a?(Class) })
    end

    # The direct superclass
    #
    # @return [ClassMirror]
    def superclass
      Mirrors.reflect(subject_send_from_class(:superclass))
    end

    # The known subclasses
    #
    # @return [Array<ClassMirror>]
    def subclasses
      mirrors(ObjectSpace.each_object(Class).select { |a| a.superclass == @subject })
    end

    # The list of ancestors
    #
    # @return [Array<ClassMirror>]
    def ancestors
      mirrors(subject_send_from_module(:ancestors))
    end

    # The constants defined within this class. This includes nested
    # classes and modules, but also all other kinds of constants.
    #
    # @return [Array<FieldMirror>]
    def constants
      field_mirrors(subject_send_from_module(:constants))
    end

    # Searches for the named constant in the mirrored namespace. May
    # include a colon (::) separated constant path. This _may_ trigger
    # an autoload!
    #
    # @return [ClassMirror, nil] the requested constant, or nil
    def constant(str)
      path = str.to_s.split("::")
      c = path[0..-2].inject(@subject) do |klass, s|
        Mirrors.rebind(Module, klass, :const_get).call(s)
      end

      field_mirror((c || @subject), path.last)
    rescue NameError => e
      p e
      nil
    end

    # The full nesting.
    #
    # @return [Array<ClassMirror>]
    def nesting
      ary = []
      subject_send_from_module(:name).split('::').inject(Object) do |klass, str|
        ary << Mirrors.rebind(Module, klass, :const_get).call(str)
        ary.last
      end
      ary.reverse
    rescue NameError
      [@subject]
    end

    # The classes nested within the subject. Should _not_ trigger
    # autloads!
    #
    # @return [Array<ClassMirror>]
    def nested_classes
      nc = subject_send_from_module(:constants).map do |c|
        # do not trigger autoloads
        if subject_send_from_module(:const_defined?, c) && !subject_send_from_module(:autoload?, c)
          subject_send_from_module(:const_get, c)
        end
      end

      consts = nc.compact.select do |c|
        Mirrors.rebind(Kernel, c, :is_a?).call(Module)
      end

      mirrors(consts.sort_by { |c| Mirrors.rebind(Module, c, :name).call })
    end

    def nested_class_count
      nested_classes.count
    end

    # The instance methods of this class. To get to the class methods,
    # ask the #singleton_class for its methods.
    #
    # @return [Array<MethodMirror>]
    def methods
      pub_names  = subject_send_from_module(:public_instance_methods, false)
      prot_names = subject_send_from_module(:protected_instance_methods, false)
      priv_names = subject_send_from_module(:private_instance_methods, false)

      mirrors = []
      pub_names.sort.each do |n|
        mirrors << Mirrors.reflect(subject_send_from_module(:instance_method, n))
      end
      prot_names.sort.each do |n|
        mirrors << Mirrors.reflect(subject_send_from_module(:instance_method, n))
      end
      priv_names.sort.each do |n|
        mirrors << Mirrors.reflect(subject_send_from_module(:instance_method, n))
      end
      mirrors
    end

    # The instance method of this class or any of its superclasses
    # that has the specified selector
    #
    # @return [MethodMirror, nil] the method or nil, if none was found
    def method(name)
      Mirrors.reflect(subject_send_from_module(:instance_method, name))
    end

    def name
      subject_send_from_module(:inspect)
    end

    def demodulized_name
      name.split('::').last
    end

    def intern_method_mirror(mirror)
      @method_mirrors[mirror.name] ||= mirror
    end

    def intern_field_mirror(mirror)
      @field_mirrors[mirror.name] ||= mirror
    end
  end
end
