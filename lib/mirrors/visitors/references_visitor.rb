require 'mirrors/visitors/iseq_visitor'
require 'mirrors/index/marker'

module Mirrors
  # ReferencesVisitor examines opcodes and records references to
  # classes, methods, and fields

  class ReferencesVisitor < Mirrors::ISeqVisitor
    attr_reader :markers

    def initialize
      super
      @markers = []
    end

    protected

    def visit(bytecode)
      case bytecode.first
      when :getinstancevariable
        @markers << field_marker(bytecode[1])
      when :getconstant
        @markers << class_marker(bytecode.last)
      when :opt_send_without_block
        @markers << method_marker(bytecode[1][:mid])
      end
    end

    private

    def class_marker(name)
      Marker.new(
        type: Mirrors::Marker::TYPE_CLASS_REFERENCE,
        message: name,
        file: @absolute_path,
        line: @line
      )
    end

    def field_marker(name)
      Marker.new(
        type: Mirrors::Marker::TYPE_FIELD_REFERENCE,
        message: name,
        file: @absolute_path,
        line: @line
      )
    end

    def method_marker(name)
      Marker.new(
        type: Mirrors::Marker::TYPE_METHOD_REFERENCE,
        message: name,
        file: @absolute_path,
        line: @line
      )
    end
  end
end
