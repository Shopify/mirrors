module Mirrors
  # Methods here follow the pattern of:
  # <target>_<instance or singleton>_<invoke or method>
  #
  # * target is the owner of the method
  # * instance or singleton indicates whether we want an instance method or a
  #   singleton method from the target
  # * invoke calls the method on a receiver, which must be compatible with the
  #   method. method returns the method to bind to whatever receiver you want.

  @unbound_module_instance_methods = {}
  @unbound_class_singleton_methods = {}

  def self.module_instance_invoke(receiver, msg)
    module_instance_method(msg).bind(receiver).call
  end

  def self.module_instance_method(msg)
    @unbound_module_instance_methods[msg] ||= Module.instance_method(msg)
  end

  def self.class_singleton_invoke(receiver, msg)
    class_singleton_method(msg).bind(receiver).call
  end

  def self.class_singleton_method(msg)
    @unbound_class_singleton_methods[msg] ||= Class.method(msg).unbind
  end
end
