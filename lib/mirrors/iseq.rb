require 'mirrors/iseq/references_visitor'

module Mirrors
  # Tools for walking the bytecode of a method and extracting useful
  # information.
  module ISeq
    # Walk an iseq, aggregating all the references in this method to other
    # classes, methods, and constants.
    #
    # @see ReferencesVisitor
    # @param [RubyVM::InstructionSequence] iseq iseq to walk
    # @return [Array<Marker>] list of references found in the method
    def self.references(iseq)
      visitor = ReferencesVisitor.new(iseq)
      visitor.markers
    end
  end
end
