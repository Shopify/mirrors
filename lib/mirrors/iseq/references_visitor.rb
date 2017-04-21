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
        aggregation_type = false
        const = []
        const_line = -1

        instructions.each do |bytecode|
          op = bytecode.first

          if aggregation_type && op != :getconstant
            const_name = const.map(&:last).join('::').to_sym # e.g. A::B
            mark = case aggregation_type
            when :static
              static_constant_marker(const_name, const_line)
            when :static_root
              static_constant_marker("::#{const_name}".to_sym, const_line)
            else # :dynamic
              dynamic_constant_marker(const_name, const_line)
            end
            @markers << mark
            aggregation_type = nil
            const.clear
            const_line = -1
          end

          case op
          when :getinstancevariable
            @markers << field_marker(bytecode[1])
          when :getconstant
            unless aggregation_type
              aggregation_type = if @last.first == :getinlinecache
                # this is a static constant reference (e.g. A::B).
                :static
              elsif @last == [:putobject, Object]
                # also a static constant reference, on the root scope
                # (e.g. ::A::B).
                :static_root
              else
                # this is a dynamic constant reference. we don't understand
                # what the reveiver is (e.g. f::A::B).
                :dynamic
              end
            end
            const_line = @line
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

      def static_constant_marker(name, line = @line)
        Marker.new(
          type: Mirrors::Marker::TYPE_STATIC_CONSTANT_REFERENCE,
          message: name,
          file: @absolute_path,
          line: line
        )
      end

      def dynamic_constant_marker(name, line = @line)
        Marker.new(
          type: Mirrors::Marker::TYPE_DYNAMIC_CONSTANT_REFERENCE,
          message: name,
          file: @absolute_path,
          line: line
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
