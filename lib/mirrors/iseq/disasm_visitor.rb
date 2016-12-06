require 'mirrors/iseq/visitor'

module Mirrors
  module ISeq
    # DisasmVisitor prints a disassembled version of the bytecodes
    # in a format similar to that used by the disasm() method.
    class DisasmVisitor < Visitor
      def visit(bytecode)
        puts " #{format('%03d', @pc)} #{bytecode}  (#{@line})"
      end
    end
  end
end
