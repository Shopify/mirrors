module Mirrors
  # A mirror to track an instance variable on an object.
  # @see FieldMirror
  class InstanceVariableMirror < FieldMirror
    # @return [Mirror] the reflected value. Could be any type of {Mirror}, but
    #   most likely to be an {ObjectMirror}.
    def value
      Mirrors.reflect(@object.instance_variable_get(@name))
    end

    # @return [false] instance variables are always private.
    def public?
      false
    end

    # @return [false] instance variables are always private.
    def protected?
      false
    end

    # @return [true] instance variables are always private.
    def private?
      true
    end
  end
end
