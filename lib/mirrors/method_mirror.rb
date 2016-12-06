require 'method_source'
require 'base64'
require 'ripper'
require 'pp'
require 'mirrors/iseq/references_visitor'

module Mirrors
  # A MethodMirror should reflect on methods, but in a more general
  # sense than the Method and UnboundMethod classes in Ruby are able
  # to offer.
  #
  # In actual execution, a method is pretty much every chunk of code,
  # even loading a file triggers a process not unlike compiling a
  # method (if only for the side-effects). Method mirrors should allow
  # access to the runtime objects, but also to their static
  # representations (bytecode, source, ...), their debugging
  # information and statistical information
  class MethodMirror < Mirror
    # @return [String, nil] The filename, if available
    def file
      sl = source_location
      sl ? sl.first : nil
    end

    # @return [Fixnum, nil] The source line, if available
    def line
      sl = source_location
      sl && sl.last ? sl.last - 1 : nil
    end

    # @return [String] The method name
    def selector
      @subject.name.to_s
    end

    # @return [ClassMirror] The class this method was originally defined in
    def defining_class
      Mirrors.reflect @subject.send(:owner)
    end

    # Return the value the block argument, or nil
    #
    # @return [String, nil]
    def block_argument
      args(:block).first
    end

    # Returns a field mirror with name and possibly value of the splat
    # argument, or nil, if there is none to this method.
    #
    # @return [String, nil]
    def splat_argument
      args(:rest).first
    end

    # Returns names and values of the optional arguments.
    #
    # @return [Array<String>, nil]
    def optional_arguments
      args(:opt)
    end

    # Returns the name and possibly values of the required arguments
    #
    # @return [Array<String>]
    def required_arguments
      args(:req)
    end

    # Queries the method for it's arguments and returns a list of
    # mirrors that hold name and value information.
    #
    # @return [Array<String>]
    def arguments
      @subject.send(:parameters).map { |_, a| a.to_s }
    end

    # Is the method :public, :private, or :protected?
    #
    # @return [String]
    def visibility
      return :public  if visibility?(:public)
      return :private if visibility?(:private)
      :protected
    end

    def protected?
      visibility?(:protected)
    end

    def public?
      visibility?(:public)
    end

    def private?
      visibility?(:private)
    end

    def super_method
      owner = @subject.send(:owner)

      if owner.is_a?(Class)
        meth = Mirrors
          .class_singleton_method(:allocate)
          .bind(instance)
          .super_method
          .unbind
      else
        meth = @subject.bind(owner).super_method.unbind
      end

      meth ? Mirrors.reflect(meth) : nil
    end

    # @return [String,nil] The source code of this method
    def source
      @source ||= unindent(@subject.send(:source))
    rescue MethodSource::SourceNotFoundError
      nil
    end

    # @return [String,nil] The pre-definition comment of this method
    def comment
      @subject.send(:comment)
    rescue MethodSource::SourceNotFoundError
      nil
    end

    # Returns the instruction sequence for the method (cached)
    def iseq
      @iseq ||= RubyVM::InstructionSequence.of(@subject)
    end

    # Returns the disassembled code if available.
    #
    # @return [String, nil] human-readable bytedcode dump
    def bytecode
      @bytecode ||= iseq.disasm if iseq
      @bytecode
    end

    # Returns the parse tree if available
    #
    # @return [String, nil] prettified AST
    def sexp
      src = source
      src ? Ripper.sexp(src).pretty_inspect : nil
    end

    # Returns the compiled code if available.
    #
    # @return [RubyVM::InstructionSequence, nil] native code
    def native_code
      RubyVM::InstructionSequence.of(@subject)
    end

    def name
      @subject.name
    end

    def references
      Mirrors::ISeq.references(@subject)
    end

    private

    def visibility?(type)
      list = @subject.send(:owner).send("#{type}_instance_methods")
      list.any? { |m| m.to_s == selector }
    end

    def args(type)
      args = []
      @subject.send(:parameters).select { |t, n| args << n.to_s if t == type }
      args
    end

    def source_location
      @subject.send(:source_location)
    end

    def unindent(str)
      lines = str.split("\n")
      return str if lines.empty?

      indents = lines.map do |line|
        if line =~ /\S/
          line.start_with?(" ") ? line.match(/^ +/).offset(0)[1] : 0
        end
      end
      indents.compact!

      if indents.empty?
        # No lines had any non-whitespace characters.
        return ([""] * lines.size).join "\n"
      end

      min_indent = indents.min
      return str if min_indent.zero?
      lines.map { |line| line =~ /\S/ ? line.gsub(/^ {#{min_indent}}/, "") : line }.join("\n")
    end
  end
end
