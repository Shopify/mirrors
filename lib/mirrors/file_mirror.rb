require 'mirrors/iseq'

module Mirrors
  # Represents a file on disk, normally corresponding to an entry in
  # +$LOADED_FEATURES+ or the definition point of a class or method.
  class FileMirror < Mirror
    # Trivial object to represent a file path. Only really useful for
    # {Mirrors.reflect} to unambiguously determine the mirror type.
    File = Struct.new(:path)

    # @return [String] path to the file on disk (uniquely identifying)
    def name
      @reflectee.path
    end

    # @return [String] path to the file on disk
    def path
      @reflectee.path
    end

    # @return [RubyVM::InstructionSequence] Result of compiling the file to
    #   YARV bytecode.
    def native_code
      @native_code ||= RubyVM::InstructionSequence.compile_file(path)
    rescue Errno::ENOENT, Errno::EPERM
      nil
    end

    # @return [String,nil] Disassembly of the YARV bytecode for this file, if
    #   available.
    def bytecode
      @bytecode ||= native_code ? native_code.disasm : nil
    end

    # @return [Array<Marker>,nil] list of all methods invoked in this file,
    #   including method bodies.
    def references
      @references ||= begin
        ISeq.references(native_code)
      end
    end

    # @return [String,nil] The source code of this method, if available.
    def source
      ::File.read(path)
    rescue Errno::ENOENT, Errno::EPERM
      nil
    end
  end
end
