require 'mirrors/marker'
require 'mirrors/iseq/yasmdata'

module Mirrors
  module ISeq
    # examines opcodes and aggregates references to classes, methods, and
    # fields.
    class ReferencesVisitor
      def initialize(native_code)
        @markers = []
        @last = []

        @iseq = native_code

        # extract fields from iseq
        @magic,
        @major_version,
        @minor_version,
        @format_type,
        @misc,
        @label,
        @path,
        @absolute_path,
        @first_lineno,
        @type,
        @locals,
        @params,
        @catch_table,
        @bytecode = @iseq.to_a

        # walk state
        @pc = 0 # program counter
        @label = nil # current label
      end

      def markers
        find_references
        @markers
      end

      def find_references
        aggregating = false
        const = []

        instructions.each do |bytecode|
          op = bytecode.first

          if aggregating
            if op != :getconstant
              qualified = const.map do |bc|
                bc.first == :putobject ? '' : bc.last
              end.join('::').to_sym
              @markers << class_marker(qualified)
              aggregating = false
              const.clear
            end
          end

          case op
          when :getinstancevariable
            @markers << field_marker(bytecode[1])
          when :getconstant
            unless aggregating
              aggregating = true
              if @last == [:putobject, Object]
                const << @last
              end
            end
            const << bytecode
          when :opt_send_without_block
            @markers << method_marker(bytecode[1][:mid])
          when :invokesuper
            @markers << method_marker(:super)
          when :defineclass
            @markers.concat(markers_from_block(bytecode[2]))
          when :putiseq
            @markers.concat(markers_from_block(bytecode[1]))
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
      end

      def instructions
        Enumerator.new do |enum|
          next unless @bytecode # C extensions have no bytecode
          @pc = 0
          @label = nil
          @bytecode.each do |bc|
            case bc
            when Numeric
              @line = bc
            when Symbol
              @label = bc
            when Array # an actual instruction
              @opcode = YASMData.id2insn_no(bc.first)
              raise "unknown opcode #{bc}" unless @opcode
              enum << bc
              # should we pass this along with bc?
              @pc += YASMData.insn_no2size(@opcode)
            end
          end
        end
      end

      private

      FLAG_ARGS_BLOCKARG = 0x02

      def markers_from_block(native_code)
        vis = self.class.new(native_code)
        vis.markers
      end

      def class_marker(name)
        Marker.new(
          type: Mirrors::Marker::TYPE_CONSTANT_REFERENCE,
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
