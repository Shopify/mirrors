module Mirrors
  # Basic mirror class. Not overtly useful in and of itself, this is primarily
  # a base class for other Mirror types. Look at {ClassMirror}, {MethodMirror},
  # and {ObjectMirror} to get a feel for this.
  #
  # @!attribute [r] reflectee
  #   @return [Object] the actual reflected object
  class Mirror
    attr_reader :reflectee

    # Prefer {Mirrors.reflect}. Wraps the given object in a mirror. More useful
    # also via more specific subclassees.
    def initialize(obj)
      @reflectee = obj
    end

    # @deprecated We shouldn't depend on object IDs in LG. Remove this.
    # @return [String] stringified object_id of the reflectee.
    def subject_id
      @reflectee.__id__.to_s
    end

    # Whatever might be considered the 'name' of the object. Best-effort.
    # @return [String]
    def name
      if reflectee_is_a?(String)
        @reflectee
      elsif reflectee_is_a?(Symbol)
        # if you've overridden +Symbol#to_s+, you deserve whatever you get.
        @reflectee.to_s
      else
        # +ClassMirror+ overrides this to force +Module#inspect+ to be used,
        # but with some generic object, we can't do much better than
        # whatever the author tells us we have.
        @reflectee.inspect
      end
    end

    # Is the given object the same as the reflectee of this mirror?
    # @return [Boolean]
    def mirrors?(other)
      @reflectee == other
    end

    private

    def reflectee_is_a?(klass)
      Mirrors.rebind(Kernel, @reflectee, :is_a?).call(klass)
    end

    def reflectee_instance_variables
      Mirrors.rebind(Kernel, @reflectee, :instance_variables).call
    end

    def reflectee_class
      Mirrors.rebind(Kernel, @reflectee, :class).call
    end

    def reflectee_singleton_class
      Mirrors.rebind(Kernel, @reflectee, :singleton_class).call
    end

    def mirrors(list)
      list.collect { |e| Mirrors.reflect(e) }
    end
  end
end
