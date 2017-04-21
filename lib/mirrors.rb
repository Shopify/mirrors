require 'logger'
require 'mirrors/mirror'
require 'mirrors/package'
require 'mirrors/object_mirror'
require 'mirrors/class_mirror'
require 'mirrors/field_mirror'
require 'mirrors/file_mirror'
require 'mirrors/method_mirror'
require 'mirrors/package_mirror'
require 'mirrors/application_package_support'
require 'mirrors/package_inference'
require 'mirrors/checks'
require 'mirrors/iseq'

# Mirrors provides a parallel-world reflection API for ruby.
# See {file:README.md} for more information.
# @todo more words here
module Mirrors
  @class_mirrors = {}
  @file_mirrors = {}
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

    # Generate {FileMirror}s representing all the code currently loaded by the
    # application.
    #
    # @return [Array<FileMirror>]
    def files
      $LOADED_FEATURES
        .select { |feat| feat =~ %r{^/.*\.rb$} }
        .map { |feat| Mirrors.reflect(FileMirror::File.new(feat)) }
    end

    # Generate PackageMirrors representing all the "packages" in the system.
    #
    # @return [Array<PackageMirror>]
    def packages
      modules.map(&:package).uniq!
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

    # Search all methods of all classes for references to the provided
    # method name.
    #
    # @param [Symbol] message the method name to search for
    # @return [Array<Marker>]
    def senders_of(message)
      marks = []
      Mirrors.classes.each do |klass|
        [:instance_methods, :class_methods].each do |group|
          klass.send(group).each do |method|
            method.references.each do |mark|
              marks << mark if mark.message == message
            end
          end
        end
      end
      marks
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

    # Create a mirror for a given object in the system under
    # observation. This is *the* factory method for all mirror
    # instances, interning and cache invalidation will be added here.
    #
    # @param [Object] obj
    # @return [Mirror]
    def reflect(obj)
      reflector = REFLECTORS[basic_class(obj)]
      send(reflector, obj)
    end

    REFLECTORS = Hash.new(:reflect_object).merge(
      FieldMirror::Field => :reflect_field,
      FileMirror::File   => :reflect_file,
      Method             => :reflect_method,
      UnboundMethod      => :reflect_method,
      Class              => :reflect_class,
      Module             => :reflect_class,
      Mirrors::Package   => :reflect_package,
    ).freeze
    private_constant :REFLECTORS

    private

    def reflect_field(obj)
      mirror = case obj.name.to_s
      when /^@@/
        ClassVariableMirror.new(obj)
      when /^@/
        # instance variables not interned as they are not guaranteed to be
        # present in all instances
        InstanceVariableMirror.new(obj)
      else
        ConstantMirror.new(obj)
      end
      owner = mirror.owner
      # It can also be an ObjectMirror, which doesn't intern.
      return mirror unless owner.is_a?(ClassMirror)
      owner.intern_field_mirror(mirror)
    end

    def reflect_file(obj)
      mirror = FileMirror.new(obj)
      @file_mirrors[mirror.name] ||= mirror
    end

    def reflect_method(obj)
      mirror = MethodMirror.new(obj)
      if mirror.defining_class.respond_to?(:intern_method_mirror)
        mirror = mirror.defining_class.intern_method_mirror(mirror)
      end
      mirror
    end

    def reflect_class(obj)
      mirror = ClassMirror.new(obj)
      @class_mirrors[mirror.name] ||= mirror
    end

    def reflect_package(obj)
      mirror = PackageMirror.new(obj)
      @package_mirrors[mirror.name] ||= mirror
    end

    def reflect_object(obj)
      ObjectMirror.new(obj)
    end

    # find the class of obj
    def basic_class(obj)
      Mirrors.rebind(Kernel, obj, :class).call
    end

    def mirrors(list)
      list.map { |e| reflect(e) }
    end
  end
end
