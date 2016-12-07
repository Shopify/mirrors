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

    def mirrors(list)
      list.collect { |e| Mirrors.reflect(e) }
    end

    def subject_send(owner, message, *args)
      Mirrors.rebind(owner, @subject, message).call(*args)
    end
  end
end
