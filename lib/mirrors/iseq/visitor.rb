require 'mirrors/iseq/yarvdata'

module Mirrors
  module ISeq
    # Walks bytecode of methods and calls {#visit} for each instruction.
    # Internally it tracks the state of the current +@pc+, +@line+, and
    # +@label+ during the walk.
    #
    # @abstract Subclasses override {#visit}.
    class Visitor
      # Walk the given bytecode, invoking {#visit} for each instruction.
      # @param [RubyVM::InstructionSequence] native_code
      # @see MethodMirror#native_code
      # @return [Visitor] +self+. It's the side effects from {#visit} that are
      #   interesting.
      def call(native_code)
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
        walk
        self
      end

      # Invoked for each instruction as the bytecode stream is walked.
      # @abstract
      # @param [Array<Object>] _bytecode
      def visit(_bytecode)
        raise NotImplementedError, 'subclass responsibility'
      end

      FLAG_ARGS_BLOCKARG = 0x02

      private

      # walk the opcodes
      def walk
        return unless @bytecode # C extensions have no bytecode

        @pc = 0
        @label = nil
        @bytecode.each do |bc|
          case bc
          when Numeric
            @line = bc
          when Symbol
            @label = bc
          when Array # an actual instruction
            @opcode = YARVData::INSTRUCTION_NUMBERS[bc.first]
            unrecognized_bytecode(bc) unless @opcode
            visit(bc)
            @pc += YARVData::LENGTH_INFO[@opcode]
          end
        end
      end

      def stack_increase(bc)
        incr = YARVData::STACK_INCREASE[bc.first]
        case incr
        when Fixnum
          incr
        when :send, :invokesuper
          -(bc[1][:orig_argc] + (bc[1][:flag] & FLAG_ARGS_BLOCKARG > 0 ? 1 : 0))
        when :expandarray
          bc[1] - 1 + (bc[2] & 1 > 0 ? 1 : 0)
        when :opt_send_without_block
          -bc[1][:orig_argc]
        when :invokeblock
          1 - bc[1][:orig_argc]
        when :zero_minus_op_0
          -bc[1]
        when :zero_minus_op_1
          -bc[2]
        when :op_0
          bc[1]
        when :op_1
          bc[2]
        when :one_minus_op_0
          1 - bc[1]
        when :one_minus_op_1
          1 - bc[2]
        else
          raise '???'
        end
      end
    end
  end
end
