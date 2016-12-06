require 'logger'
require 'mirrors/mirror'
require 'mirrors/object_mirror'
require 'mirrors/class_mirror'
require 'mirrors/field_mirror'
require 'mirrors/method_mirror'
require 'mirrors/package_mirror'
require 'mirrors/package_inference'
require 'mirrors/class_mixin'
require 'mirrors/index/indexer'

module Mirrors
  extend self

  @class_mirrors = {}
  @constant_mirrors = {}
  @watches = {}
  @logger = Logger.new(STDOUT)

  def packages
    packages = {}
    # Object is the top-level.
    Object.constants.each do |const|
      pkg = PackageInference.infer_from_toplevel(const)
      packages[pkg] = true
    end
    toplevel_packages = packages.keys.map { |pkg| pkg.sub(/:.*/, '') }.sort
    package_mirrors(toplevel_packages)
  end

  # This method can be used to query the system for known modules. It
  # is not guaranteed that all possible modules are returned.
  #
  # @return [Array<ClassMirror>] a list of class mirrors
  def modules
    instances_of(Module).sort! { |a, b| a.name <=> b.name }
  end

  # This method can be used to query the system for known classes. It
  # is not guaranteed that all possible classes are returned.
  #
  # @return [Array<ClassMirror>] a list of class mirrors
  def classes
    instances_of(Class).sort! { |a, b| a.name <=> b.name }
  end

  # Query the system for objects that are direct instances of the
  # given class.
  # @param [Class]
  # @return [Array<ObjectMirror>] a list of appropriate mirrors for the requested objects
  def instances_of(klass)
    mirrors(ObjectSpace.each_object(klass).select { |obj| obj.class == klass })
  end

  # Ask the system to find the object with the given object id
  # @param [Numeric] object id
  # @return [ObjectMirror, NilClass] the object mirror or nil
  def object_by_id(id)
    obj = ObjectSpace._id2ref(id)
    obj ? reflect(obj) : nil
  end

  # Query the system for implementors of a particular message
  # @param [String] the message name
  # @return [Array<MethodMirror>] the implementing methods
  def implementations_of(str)
    methods = ObjectSpace.each_object(Module).collect do |m|
      ims = m.instance_methods(false).collect { |s| m.instance_method(s) }
      cms = m.methods(false).collect { |s| m.method(s) }
      ims + cms
    end.flatten

    mirrors(methods.select { |m| m.name.to_s == str.to_s })
  end

  def references_to(str)
    filtered = {}
    Mirrors.classes.each do |klass|
      klass.methods.each do |m|
        refs = m.references.select { |marker| marker.message.match(str) }
        filtered[m] = refs unless refs.empty?
      end
    end
    filtered
  end

  # Create a mirror for a given object in the system under
  # observation.  This is *the* factory method for all mirror
  # instances, interning and cache invalidation will be added here.
  #
  # @param [Object]
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
    Kernel.instance_method(:class).bind(obj).call
  end

  # find the class name of obj
  def basic_class_name(klass)
    Class.instance_method(:name).bind(klass).call
  end

  def intern_class_mirror(mirror)
    interned = @class_mirrors[mirror.name] ||= mirror
  end

  def intern_method_mirror(mirror)
    mirror.defining_class.intern_method_mirror(mirror)
  end

  def intern_field_mirror(mirror)
    mirror.defining_class.intern_field_mirror(mirror)
  end

  def mirrors(list)
    list.map { |e| reflect(e) }
  end

  def package_mirrors(list)
    list.map { |e| PackageMirror.reflect(e) }
  end
end
