module Mirrors
  # Refers to a particular location in a source file. with some intent/message
  # indicated by the {#message} and {#type} fields.
  #
  # @!attribute [r] message
  #   @return [String] descriptive text explaining the marker; varies by {type}
  # @!attribute [r] type
  #   @return [Symbol] one of the +Marker::TYPE_*+ constants
  # @!attribute [r] file
  #   @return [String,nil] file to which the marker points, if any
  # @!attribute [r] line
  #   @return [Integer] line to which the marker points; -1 indicating none.
  # @!attribute [r] start_column
  #   @return [Integer] beginning column index to which the marker points; -1
  #     indicating none.
  # @!attribute [r] end_column
  #   @return [Integer] end column index to which the marker points; -1
  #     indicating none.
  class Marker
    attr_reader :message, :type, :file, :line, :start_column, :end_column

    # for later use
    # TYPE_TASK    = :'mirrors.marker.task'
    # TYPE_PROBLEM = :'mirrors.marker.problem'
    # TYPE_TEXT    = :'mirrors.marker.text'

    # the marker indicates a location in source where a class (named as
    # {#message}) is referenced.
    TYPE_CLASS_REFERENCE = :'mirrors.marker.text.class_reference'
    # the marker indicates a location in source where a method (named as
    # {#message}) is referenced.
    TYPE_METHOD_REFERENCE = :'mirrors.marker.text.method_reference'
    # the marker indicates a location in source where a field (named as
    # {#message}) is referenced. This can be a class variables, class instance
    # variable, or constant, dependent on whether {#message} starts with 0, 1,
    # or 2 +@+s.
    TYPE_FIELD_REFERENCE = :'mirrors.marker.text.field_reference'

    # If the marker isn't associated to a particular line, {#line} will be +-1+.
    NO_LINE = -1
    # If the marker isn't associated to a column range, {#start_column} and/or
    # {#end_column} will be +-1+.
    NO_COLUMN = -1

    # @param [Symbol] type One of the +Marker::TYPE_*+ constants, indicating
    #   what the intent of this marker is.
    # @param [String] message +type+-specific metadata, e.g. a class or method
    #   name.
    # @param [String] file see {#file}
    # @param [Integer] line see {#line}
    # @param [Integer] start_column see {#start_column}
    # @param [Integer] end_column see {#end_column}
    def initialize(
      type:,
      message: '',
      file: nil,
      line: NO_LINE,
      start_column: NO_COLUMN,
      end_column: NO_COLUMN
    )
      @type = type
      @message = message
      @file = file
      @line = line
      @start_column = start_column
      @end_column = end_column
    end

    # @!visibility private
    def ==(other)
      type == other.type && \
        message == other.message && \
        line == other.line && \
        start_column == other.start_column && \
        end_column == other.end_column
    end

    # @!visibility private
    def eql?(other)
      self == other
    end

    # @!visibility private
    def hash
      [@type, @message, @line, @start_column, @end_column].hash
    end
  end
end
