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
        @last = []
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
        when :defineclass
          @markers.concat(markers_from_block(bytecode[2]))
        when :send
          @markers << method_marker(bytecode[1][:mid])
          if (bytecode[1][:flag] & FLAG_ARGS_BLOCKARG) > 0
            if @last[0] == :putobject && @last[1].is_a?(Symbol)
              @markers << method_marker(@last[1])
            end
          else
            @markers.concat(markers_from_block(bytecode[3]))
          end
        end
        @last = bytecode
        nil
      end

      private

      FLAG_ARGS_BLOCKARG = 0x02

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
