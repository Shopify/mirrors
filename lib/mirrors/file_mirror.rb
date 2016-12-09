require 'mirrors/iseq/references_visitor'

module Mirrors
  class FileMirror < Mirror
    File = Struct.new(:path)

    def name
      @reflectee.path
    end

    def path
      @reflectee.path
    end

    def native_code
      @native_code ||= RubyVM::InstructionSequence.compile_file(path)
    end

    def references
      @references ||= begin
        visitor = Mirrors::ISeq::ReferencesVisitor.new
        visitor.call(native_code)
        visitor.markers
      end
    end

    def source
      ::File.read(path)
    end
  end
end
