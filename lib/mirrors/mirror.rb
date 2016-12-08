module Mirrors
  # Basic mirror class. Not overtly useful in and of itself, this is primarily
  # a base class for other Mirror types. Look at {ClassMirror}, {MethodMirror},
  # and {ObjectMirror} to get a feel for this.
  class Mirror
    # Prefer {Mirrors.reflect}. Wraps the given object in a mirror. More useful
    # also via more specific subclassees.
    def initialize(obj)
      @subject = obj
    end

    # @deprecated We shouldn't depend on object IDs in LG. Remove this.
    # @return [String] stringified object_id of the reflectee.
    def subject_id
      @subject.__id__.to_s
    end

    # Whatever might be considered the 'name' of the object. Best-effort.
    # @return [String]
    def name
      if subject_is_a?(String)
        @subject
      elsif subject_is_a?(Symbol)
        # if you've overridden +Symbol#to_s+, you deserve whatever you get.
        @subject.to_s
      else
        # +ClassMirror+ overrides this to force +Module#inspect+ to be used,
        # but with some generic object, we can't do much better than
        # whatever the author tells us we have.
        @subject.inspect
      end
    end

    # Is the given object the same as the subject of this mirror?
    # @return [true, false]
    def mirrors?(other)
      @subject == other
    end

    # Accessor to the reflected object
    # @return [Object]
    def reflectee
      @subject
    end

    private

    def subject_is_a?(klass)
      Mirrors.rebind(Kernel, @subject, :is_a?).call(klass)
    end

    def subject_instance_variables
      Mirrors.rebind(Kernel, @subject, :instance_variables).call
    end

    def subject_class
      Mirrors.rebind(Kernel, @subject, :class).call
    end

    def subject_singleton_class
      Mirrors.rebind(Kernel, @subject, :singleton_class).call
    end

    def mirrors(list)
      list.collect { |e| Mirrors.reflect(e) }
    end
  end
end
