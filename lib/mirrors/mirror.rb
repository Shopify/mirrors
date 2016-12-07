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

    def subject_send_from_module(message, *args)
      Mirrors.rebind(Module, @subject, message).call(*args)
    end

    def subject_send_from_kernel(message, *args)
      Mirrors.rebind(Kernel, @subject, message).call(*args)
    end

    def subject_send_from_class(message, *args)
      Mirrors.rebind(Class.singleton_class, @subject, message).call(*args)
    end
  end
end
