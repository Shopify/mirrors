require 'mirrors/iseq/references_visitor'

module Mirrors
  # Tools for walking the bytecode of a method and extracting useful
  # information.
  module ISeq
    # Walk a method, aggregating all the references in this method to other
    # classes, methods, and constants.
    #
    # @see ReferencesVisitor
    # @param [Method,UnboundMethod] iseqable method for walk
    # @return [Array<Marker>] list of references found in the method
    def self.references(iseqable)
      iseq = RubyVM::InstructionSequence.of(iseqable)
      visitor = ReferencesVisitor.new
      visitor.call(iseq)
      visitor.markers
    end
  end
end
