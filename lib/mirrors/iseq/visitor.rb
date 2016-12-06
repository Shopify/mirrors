require 'mirrors/iseq/yasmdata'

module Mirrors
  module ISeq
    # ISeqVisitor is an abstract class that knows how to walk methods and
    # call the visit() method for each instruction.  Internally it tracks the
    # state of the current @pc, @line, and @label during the walk.
    #
    class Visitor
      attr_reader :iseq, :field_refs, :method_refs, :class_refs

      # visit all the instructions in the supplied method
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

      # iterator call once for each opcode
      def visit(_bytecode)
        raise NotImplementedError, 'subclass responsibility'
      end

      private

      # walk the opcodes
      def walk
        return unless @bytecode # C extensions have no bytecode

        @pc = 0
        @label = nil
        @bytecode.each_with_index do |bc|
          if bc.class == Integer || bc.class == Fixnum
            @line = bc # bare line number
            next # line numbers are not executable
          elsif bc.class == Symbol
            @label = bc
            next # labels are not executable
          elsif bc.class == Array
            @opcode = YASMData.id2insn_no(bc.first)
            unrecognized_bytecode(bc) unless @opcode
            visit(bc)
            @pc += YASMData.insn_no2size(@opcode)
          else
            unrecognized_bytecode(bc)
          end
        end
      end

      # emit diagnostics and signal that an unrecognized opcode was encountered
      def unrecognized_bytecode(bc)
        puts '-----------------bytecode ---------------------'
        puts "bytecode=#{bc}  class=#{bc.class}"
        puts '---------------- disassembly ------------------'
        puts @iseq.disasm
        puts '---------------- bytecode ------------------'
        @bytecode.each { |c| puts c.inspect }
        raise "Urecognized bytecode:#{bc} at index:#{@pc}"
      end
    end
  end
end
