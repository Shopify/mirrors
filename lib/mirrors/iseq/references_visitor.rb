require 'mirrors/iseq/visitor'
require 'mirrors/marker'

module Mirrors
  module ISeq
    # examines opcodes and aggregates references to classes, methods, and
    # fields.
    #
    # @!attribute [r] markers
    #   @return [Array<Marker>] after {#call}, the class/method/field
    #     references found in the bytecode.
    class ReferencesVisitor < Visitor
      attr_reader :markers

      def initialize
        super
        @markers = []
      end

      # If an instruction represents an access to an ivar, constant, or method
      # invocation, record it as such in {#markers}. Invoked by {#call}.
      #
      # @param [Array<Object>] bytecode a single instruction
      # @return [nil]
      def visit(bytecode)
        case bytecode.first
        when :getinstancevariable
          @markers << field_marker(bytecode[1])
        when :getconstant
          @markers << class_marker(bytecode.last)
        when :opt_send_without_block
          @markers << method_marker(bytecode[1][:mid])
        when :send
          @markers << method_marker(bytecode[1][:mid])
          @markers.concat(markers_from_block(bytecode[3]))
        end
        nil
      end

      private

      def markers_from_block(native_code)
        vis = self.class.new
        vis.call(native_code)
        vis.markers
      end

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
end
