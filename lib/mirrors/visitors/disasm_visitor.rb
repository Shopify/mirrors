require 'mirrors/visitors/iseq_visitor'

module Mirrors
  # DisasmVisitor prints a disassembled version of the bytecodes
  # in a format similar to that used by the disasm() method.
  class DisasmVisitor < Mirrors::ISeqVisitor
    def visit(bytecode)
      puts " #{'%03d' % @pc} #{bytecode}  (#{@line})"
    end
    end
end
