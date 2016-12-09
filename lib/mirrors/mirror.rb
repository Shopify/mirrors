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

    # Whatever might be considered the 'name' of the object. Best-effort.
    # @return [String]
    def name
      if reflectee_is_a?(String)
        @reflectee
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

    # @return [ClassMirror] The singleton class of this class
    def singleton_class
      sc = Mirrors.rebind(Kernel, @reflectee, :singleton_class).call
      scm = Mirrors.reflect(sc)
      scm.singleton_instance = self
      scm
    end

    private

    def reflectee_is_a?(klass)
      Mirrors.rebind(Kernel, @reflectee, :is_a?).call(klass)
    end

    def reflectee_instance_variables
      Mirrors.rebind(Kernel, @reflectee, :instance_variables).call
    end

    def mirrors(list)
      list.collect { |e| Mirrors.reflect(e) }
    end
  end
end
