require 'mirrors/iseq/visitor'

module Mirrors
  module ISeq
    # Prints a disassembled version of the bytecodes in a format similar to
    # that used by +RubyVM::InstructionSequence#disasm+.
    class DisasmVisitor < Visitor
      # Prints the loaded instruction, annotated with the value of +@pc+ and
      # +@line+. invoked by {#call}.
      #
      # @param [Array<Object>] bytecode a single instruction
      # @return [nil]
      def visit(bytecode)
        puts " #{format('%03d', @pc)} #{bytecode}  (#{@line})"
      end
    end
  end
end
