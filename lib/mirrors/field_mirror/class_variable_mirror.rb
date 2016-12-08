module Mirrors
  # A mirror to track a class variable on an object.
  # @see FieldMirror
  class ClassVariableMirror < FieldMirror
    # @return [Mirror] the reflected value. Could be any type of {Mirror}, but
    #   most likely to be an {ObjectMirror}.
    def value
      Mirrors.reflect(@object.class_variable_get(@name))
    end

    # @return [false] class variables are always private.
    def public?
      false
    end

    # @return [false] class variables are always private.
    def protected?
      false
    end

    # @return [true] class variables are always private.
    def private?
      true
    end
  end
end
