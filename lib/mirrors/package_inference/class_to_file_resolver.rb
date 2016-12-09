require 'set'

module Mirrors
  module PackageInference
    # Resolves a Class ({ClassMirror}) to a path on disk using various
    # heuristics.
    #
    # Our preferred path is to use the data recorded by the +TracePoint+
    # registered by {Mirrors::Init}, if it was +required+ early enough to
    # capture data on the provided class, but we have some fallback heuristics
    # too.
    class ClassToFileResolver
      def initialize
        @files = {}
      end

      # Attempt to resolve a {ClassMirror} to a single path on disk which
      # corresponds to its primary definition site.
      #
      # The +TracePoint+ registered in {Init} captures the filename each time a
      # class is opened. If this class was only opened once, we can simply
      # return that filepath.
      #
      # If it wasn't registered by {Init::CLASS_DEFINITION_TRACEPOINT} or if it
      # was opened more than once, we find the source file for each instance
      # and class method defined on the module, and look for text in that file
      # that looks like +class FooBar+ -- e.g. explicitly opening the class.
      # This is because many libraries will add instance methods to an argument
      # using dynamic APIs (e.g. +target.define_method(...)+)
      #
      # Failing that strategy, we choose whichever file contained the most
      # instance or class methods for this module.
      #
      # If we weren't able to determine a source location for any methods, and
      # didn't track class creation (as may be the case for some core classes
      # or C extensions), we simply return +nil+.
      #
      # @param [ClassMirror] cm the {ClassMirror} for which to determine a
      #   filename.
      # @return [String,nil] the path on disk to the defining file
      def resolve(cm)
        name = cm.name
        dname = cm.demodulized_name

        try_traced(name)                      ||
          try_fast(cm, dname)                 ||
          try_fast(cm.singleton_class, dname) ||
          try_slow(cm)                        ||
          try_slow(cm.singleton_class)
      end

      private

      def try_traced(class_name)
        return false unless defined?(Mirrors::Init)
        files = Mirrors::Init.class_files(class_name)
        files.size == 1 ? files.first : nil
      end

      def try_fast(cm, demodulized_name)
        done = Set.new
        cm.instance_methods.each do |mm|
          file = mm.file # FileMirror
          next unless file
          file = file.path # String
          next if done.include?(file)

          contents = begin
            (@files[file] ||= File.open(file, 'r') { |f| f.readpartial(4096) })
          rescue Errno::ENOENT
            # file wasn't readable
            ""
          end
          pat = /^\s+(class|module) ([\S]+::)?#{Regexp.quote(demodulized_name)}\s/
          return file if contents =~ pat
          done << file
        end
        nil
      end

      def try_slow(cm)
        defined_directly_on_class = cm.instance_methods
          .select do |mm|
            # as a mostly-useful heuristic, we just eliminate everything that was
            # defined using a template eval or define_method.
            begin
              src = mm.source
              src && src =~ /\A\s+def (self\.)?#{Regexp.quote(mm.name)}/
            rescue NoMethodError # bug in method_source
              false
            end
          end

        files = Hash.new(0)

        defined_directly_on_class.each do |mm|
          if f = mm.file
            files[f] += 1
          end
        end

        file = files.max_by { |_k, v| v }
        file ? file[0] : nil
      end
    end
  end
end
