require 'method_source'
require 'base64'
require 'ripper'
require 'mirrors/iseq/references_visitor'

module Mirrors
  # A MethodMirror should reflect on methods, but in a more general sense than
  # the Method and UnboundMethod classes in Ruby are able to offer.
  #
  # In actual execution, a method is pretty much every chunk of code, even
  # loading a file triggers a process not unlike compiling a method (if only
  # for the side-effects). Method mirrors should allow access to the runtime
  # objects, but also to their static representations (bytecode, source, ...),
  # their debugging information and statistical information
  class MethodMirror < Mirror
    def initialize(obj)
      @owner = obj.owner
      super
    end

    # @return [ClassMirror] The class this method was originally defined in
    def defining_class
      Mirrors.reflect(@reflectee.owner)
    end

    # @!group Instance Methods: Arguments

    # Queries the method for it's arguments and returns a list of
    # mirrors that hold name and value information.
    #
    # @return [Array<String>]
    def arguments
      @reflectee.parameters.map { |_, a| a.to_s }
    end

    # Return the value the block argument, if any
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
    # @return [Array<String>]
    def optional_arguments
      args(:opt)
    end

    # Returns the name and possibly values of the required arguments
    #
    # @return [Array<String>]
    def required_arguments
      args(:req)
    end

    # @!endgroup
    # @!group Instance Methods: Visibility

    # Is the method +:public+, +:private+, or +:protected+?
    # @return [:public, :private, :protected]
    def visibility
      @visibility ||= begin
        name = @reflectee.name
        if @owner.protected_instance_methods(false).include?(name)
          :protected
        elsif @owner.private_instance_methods(false).include?(name)
          :private
        else
          :public
        end
      end
    end

    # @return [Boolean] Is this a protected method?
    def protected?
      visibility == :protected
    end

    # @return [Boolean] Is this a public method?
    def public?
      visibility == :public
    end

    # @return [Boolean] Is this a private method?
    def private?
      visibility == :private
    end

    # @!endgroup
    # @!group Instance Methods: Source

    # @return [String,nil] The source code of this method, if available.
    def source
      @source ||= unindent(@reflectee.source)
    rescue MethodSource::SourceNotFoundError
      nil
    end

    # @return [String,nil] The pre-definition comment of this method, if available.
    def comment
      @comment ||= @reflectee.comment
    rescue MethodSource::SourceNotFoundError
      nil
    end

    # @see #native_code
    # @return [String,nil] the human-readable bytecode disassembly, if available.
    def bytecode
      @bytecode ||= (native_code.disasm if native_code)
    end

    # @todo this changed; update consumers to `#pretty_inspect` the result.
    # @return [String, nil] parse tree, if available.
    def sexp
      src = source
      src ? Ripper.sexp(src) : nil
    end

    # @see #bytecode
    # @return [RubyVM::InstructionSequence, nil] native code, if available
    def native_code
      @native_code ||= RubyVM::InstructionSequence.of(@reflectee)
    end

    # @return [String, nil] The filename, if available
    def file
      sl = source_location
      sl ? Mirrors.reflect(FileMirror::File.new(sl.first)) : nil
    end

    # @return [Fixnum, nil] The source line, if available
    def line
      sl = source_location
      sl && sl.last ? sl.last - 1 : nil
    end

    # @!endgroup

    # @return [Array<Marker>,nil] list of all methods invoked in the method
    #   body.
    def references
      @references ||= Mirrors::ISeq.references(@reflectee)
    end

    # @see #calls_super?
    # @return [MethodMirror,nil] Parent class/included method of the same name.
    def super_method
      meth = if @owner.is_a?(Class)
        Mirrors
          .rebind(Class.singleton_class, instance, :allocate)
          .super_method
          .unbind
      else
        @reflectee.bind(@owner).super_method.unbind
      end

      meth ? Mirrors.reflect(meth) : nil
    end

    # @see #super_method
    # @return [Boolean] Does this method call +super+?
    def calls_super?
      references.any? { |ref| ref.message == :super }
    end

    # @return [Symbol] name of the method
    def name
      @reflectee.name
    end

    private

    def args(type)
      args = []
      @reflectee.parameters.select { |t, n| args << n.to_s if t == type }
      args
    end

    def source_location
      @source_location ||= @reflectee.source_location
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
