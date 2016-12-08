module Mirrors
  # A mirror class. It is the most generic mirror and should be able
  # to reflect on any object you can get at in a given system.
  class ObjectMirror < Mirror
    # @return [FieldMirror] the instance variables of the object
    def variables
      field_mirrors(reflectee_instance_variables)
    end

    # @return [ClassMirror] the a class mirror on the runtime class object
    def reflectee_class
      Mirrors.reflect(reflectee_class)
    end

    private

    def field_mirrors(list, reflectee = @reflectee)
      list.map { |name| field_mirror(reflectee, name) }
    end

    def field_mirror(reflectee, name)
      Mirrors.reflect(FieldMirror::Field.new(reflectee, name))
    end
  end
end
