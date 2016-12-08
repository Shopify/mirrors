require 'logger'
require 'mirrors/mirror'
require 'mirrors/package'
require 'mirrors/object_mirror'
require 'mirrors/class_mirror'
require 'mirrors/field_mirror'
require 'mirrors/method_mirror'
require 'mirrors/package_mirror'
require 'mirrors/package_inference'
require 'mirrors/class_mixin'
require 'mirrors/iseq'

module Mirrors
  @class_mirrors = {}
  @package_mirrors = {}
  @constant_mirrors = {}
  @watches = {}
  @logger = Logger.new(STDOUT)
  @unbound_methods = {}

  # Indicates we weren't able to infer the root directory of the project.
  ProjectRootNotFound = Class.new(StandardError)

  class << self
    # Attempt to determine the root of the application.
    #
    # @return [String] the path on disk to the root of the application source.
    # @raise [ProjectRootNotFound] if we weren't able to infer the project
    #   root.
    def project_root
      if defined?(Bundler)
        return File.expand_path(Bundler.root)
      end
      if Dir.exist?('.git')
        return File.expand_path(Dir.pwd)
      end
      raise ProjectRootNotFound
    end

    # Unbind a method from +owner+, re-bind it to +receiver+. The result is
    # invokable with +#call+.
    #
    # @param [Module] owner The class/module from which to unbind the named
    #   instance_method. If you want a singleton/static method, you may want
    #   to pass (e.g.) +Class.singleton_class+.
    # @param [Object] receiver The object to bind the method to. It must be an
    #   instance of +owner+ or one of its descendents.
    # @param [Symbol] msg The name of the method to rebind
    #
    # @example inspect a class that may have overridden +#inspect+
    #   Mirrors.rebind(Module, klass, :inspect).call
    #
    # @return [Method] Bound method object, invokable with +#call+
    # @raise [TypeError] if the +owner+ and +receiver+ are not compatible.
    # @raise [NameError] if +msg+ does not exist on +owner+.
    def rebind(owner, receiver, msg)
      @unbound_methods[owner] ||= {}
      meth = (@unbound_methods[owner][msg] ||= owner.instance_method(msg))
      meth.bind(receiver)
    end

    # Generate PackageMirrors representing all the "packages" in the system.
    #
    # @return [Array<PackageMirror>]
    def packages
      packages = {}
      # Object is the top-level.
      Object.constants.each do |const|
        pkg = PackageInference.infer_from_toplevel(const)
        packages[pkg] = true
      end
      mirrors(packages.keys)
      # toplevel_packages = packages.keys.map { |pkg| pkg.sub(/:.*/, '') }.sort
      # package_mirrors(toplevel_packages)
    end

    # List all known modules.
    #
    # @return [Array<ClassMirror>] a list of class mirrors
    def modules
      instances_of(Module).sort_by!(&:name)
    end

    # List all known classes.
    #
    # @return [Array<ClassMirror>] a list of class mirrors
    def classes
      instances_of(Class).reject!(&:singleton_class?).sort_by!(&:name)
    end

    # Query the system for objects that are direct instances of the given
    # class.
    #
    # @param [Class] klass
    # @return [Array<ObjectMirror>] a list of appropriate mirrors for the requested objects
    def instances_of(klass)
      mirrors(ObjectSpace.each_object(klass).select { |obj| obj.class == klass })
    end

    # Ask the system to find the object with the given object id.
    #
    # @param [Numeric] id object ID
    # @return [ObjectMirror, nil] the object mirror or nil
    def object_by_id(id)
      obj = ObjectSpace._id2ref(id)
      obj ? reflect(obj) : nil
    end

    # Query the system for implementors of a particular message
    #
    # @param [String] message the message name
    # @return [Array<MethodMirror>] the implementing methods
    def implementations_of(message)
      methods = ObjectSpace.each_object(Module).collect do |m|
        ims = m.instance_methods(false).map { |s| m.instance_method(s) }
        cms = m.methods(false).map { |s| m.method(s) }
        ims + cms
      end.flatten

      mirrors(methods.select { |m| m.name.to_s == message.to_s })
    end

    # Find all methods which send the given message to any object (i.e. call
    # the named method).
    #
    # @param [Symbol] msg method name to search for
    # @return [Hash<MethodMirror,Array<Marker>>]
    def references_to(msg)
      filtered = {}
      ObjectSpace.each_object(Module).each do |mod|
        cm = reflect(mod)

        (cm.instance_methods + cm.class_methods).each do |m|
          refs = m.references.select { |marker| marker.message == msg }
          filtered[m] = refs unless refs.empty?
        end
      end
      filtered
    end

    # Create a mirror for a given object in the system under
    # observation. This is *the* factory method for all mirror
    # instances, interning and cache invalidation will be added here.
    #
    # @param [Object] obj
    # @return [Mirror]
    def reflect(obj)
      klass = basic_class(obj)
      mirror =
        if klass == FieldMirror::Field || klass == Symbol
          case obj.name.to_s
          when /^@@/
            intern_field_mirror(ClassVariableMirror.new(obj))
          when /^@/
            # instance variables not interned as they are not guaranteed to be
            # present in all instances
            InstanceVariableMirror.new(obj)
          else
            intern_field_mirror(ConstantMirror.new(obj))
          end
        elsif klass == Method || klass == UnboundMethod
          intern_method_mirror(MethodMirror.new(obj))
        elsif klass == Class || klass == Module
          intern_class_mirror(ClassMirror.new(obj))
        elsif klass == Package
          intern_package_mirror(PackageMirror.new(obj))
        else
          # TODO: revisit if ObjectMirror delivers value
          ObjectMirror.new(obj)
        end
      raise "badness" unless mirror.is_a?(Mirror)
      mirror
    end

    private

    # find the class of obj
    def basic_class(obj)
      Mirrors.rebind(Kernel, obj, :class).call
    end

    # find the class name of obj
    def basic_class_name(klass)
      Mirrors.rebind(Module, klass, :name).call
    end

    def intern_class_mirror(mirror)
      @class_mirrors[mirror.name] ||= mirror
    end

    def intern_method_mirror(mirror)
      mirror.defining_class.intern_method_mirror(mirror)
    end

    def intern_field_mirror(mirror)
      mirror.defining_class.intern_field_mirror(mirror)
    end

    def intern_package_mirror(mirror)
      @package_mirrors[mirror.name] ||= mirror
    end

    def mirrors(list)
      list.map { |e| reflect(e) }
    end
  end
end
