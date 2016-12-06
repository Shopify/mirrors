require 'mirrors/iseq/references_visitor'
require 'mirrors/iseq/disasm_visitor'

module Mirrors
  module ISeq
    def self.references(iseqable)
      iseq = RubyVM::InstructionSequence.of(iseqable)
      visitor = ReferencesVisitor.new
      visitor.call(iseq)
      visitor.markers
    end

    def self.disasm(iseqable)
      iseq = RubyVM::InstructionSequence.of(iseqable)
      visitor = DisasmVisitor.new
      visitor.call(iseq)
      visitor.markers
    end
  end
end
