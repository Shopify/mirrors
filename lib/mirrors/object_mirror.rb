module Mirrors
  # A mirror class. It is the most generic mirror and should be able
  # to reflect on any object you can get at in a given system.
  class ObjectMirror < Mirror
    # @return [FieldMirror] the instance variables of the object
    def variables
      field_mirrors(@subject.instance_variables)
    end

    # @return [ClassMirror] the a class mirror on the runtime class object
    def target_class
      Mirrors.reflect(@subject.class)
    end

    private

    def field_mirrors(list, subject = @subject)
      list.map { |name| field_mirror(subject, name) }
    end

    def field_mirror(subject, name)
      Mirrors.reflect(FieldMirror::Field.new(subject, name))
    end
  end
end
