module Mirrors
  class Marker
    TYPE_TASK = 'mirrors.marker.task'.freeze
    TYPE_PROBLEM = 'mirrors.marker.problem'.freeze
    TYPE_TEXT = 'mirrors.marker.text'.freeze
    TYPE_CLASS_REFERENCE = 'mirrors.marker.text.class_reference'.freeze
    TYPE_METHOD_REFERENCE = 'mirrors.marker.text.method_reference'.freeze
    TYPE_FIELD_REFERENCE = 'mirrors.marker.text.field_reference'.freeze

    NO_LINE = -1
    NO_COLUMN = -1

    attr_reader :message, :type, :file, :line, :start_column, :end_column

    def initialize(type: TYPE_TASK, message: '', file: nil, line: NO_LINE, start_column: NO_COLUMN, end_column: NO_COLUMN)
      @type = type
      @message = message
      @file = file
      @line = line
      @start_column = start_column
      @end_column = end_column
    end

    def ==(other)
      type == other.type && message == other.message && line == other.line && start_column == other.start_column && end_column == other.end_column
    end

    def eql?(other)
      self == other
    end

    def hash
      [@type, @message, @line, @start_column, @end_column].hash
    end

    def hashy
      [@type, @message, @line, @start_column, @end_column]
    end
  end
end
