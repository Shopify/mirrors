require 'mirrors/init'

methods = []
Mirrors.classes.each do |cm|
  methods.concat(cm.instance_methods)
  methods.concat(cm.class_methods)
end

methods.each do |meth|
  refs = meth
    .references
    .select { |ref| ref.type == Mirrors::Marker::TYPE_CLASS_REFERENCE }

  refs.each do |ref|
    begin
      const = meth.defining_class.reflectee.const_get(ref.message)
    rescue NameError
      next
    end

    mycontext = meth.defining_class
    othercontext = Mirrors.reflect(const)
    next unless othercontext.is_a?(Mirrors::ClassMirror)

    unless Mirrors::ApplicationPackageSupport.visible_from?(mycontext, othercontext)
      puts "PACKAGE NAMESPACE VIOLATION: #{marker.inspect}"
    end
  end
end
