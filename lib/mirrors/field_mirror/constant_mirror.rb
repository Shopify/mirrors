module Mirrors
  # A mirror to track a constant on an object.
  # @see FieldMirror
  class ConstantMirror < FieldMirror
    # @return [Mirror] the reflected value. Will be a {ClassMirror} if the
    #   constant refers to a class, or an {ObjectMirror} otherwise. It could in
    #   theory be any other type of {Mirror} too, depending on what was assigned
    #   to the constant.
    def value
      Mirrors.reflect(@object.const_get(@name))
    end

    # @return [Boolean] Is this a public constant? This is the default.
    def public?
      # +constants(true)+ doesn't return private constants. We could get at
      # them with +constants(false)+.
      @object.constants(true).include?(@name.to_sym)
    end

    # @return [false] constants are never protected.
    def protected?
      false
    end

    # @return [Boolean] Is this a private constant (was it tagged with
    #   +private_constant+)?
    def private?
      !@object.constants(true).include?(@name.to_sym)
    end
  end
end
