module Mirrors
  # A class to reflect on instance, class, and class instance variables,
  # as well as constants. The uniting theme here is items indexable off of a
  # +Class+ or other +Object+ with a +String+ key but without abundant extra
  # metadata like classes and methods.
  #
  # A FieldMirror is basically an owner +Object+ and a +String+ key to look up
  # the referent.
  #
  # @!attribute [r] name
  #   @return [String] the name (e.g. "@foo", "Bar", "@@baz")
  class FieldMirror < Mirror
    attr_reader :name

    # We're not really mirroring a construct that ruby gives direct access to
    # here, so we wrap up the owner and the key in this struct type.
    Field = Struct.new(:object, :name)

    def initialize(obj)
      super
      @object = obj.object
      @name = obj.name.to_s
    end

    # @return [Mirror] The object to which this field belongs. Often a +Class+,
    #   but sometimes a generic +Object+.
    def owner
      Mirrors.reflect(@object)
    end
  end
end

require 'mirrors/field_mirror/class_variable_mirror'
require 'mirrors/field_mirror/instance_variable_mirror'
require 'mirrors/field_mirror/constant_mirror'
