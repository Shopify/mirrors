module Mirrors
  # The basic mirror
  class Mirror
    def initialize(obj)
      @subject = obj
    end

    def subject_id
      @subject.__id__.to_s
    end

    # A generic representation of the object under observation.
    def name
      if @subject.is_a?(String) || @subject.is_a?(Symbol)
        @subject
      else
        @subject.inspect
      end
    end

    # The equivalent to #==/#eql? for comparison of mirrors against objects
    def mirrors?(other)
      @subject == other
    end

    # Accessor to the reflected object
    def reflectee
      @subject
    end

    private

    def subject_is_a?(klass)
      Mirrors.rebind(Kernel, @subject, :is_a?).call(klass)
    end

    def subject_singleton_class
      Mirrors.rebind(Kernel, @subject, :singleton_class).call
    end

    def mirrors(list)
      list.collect { |e| Mirrors.reflect(e) }
    end
  end
end
