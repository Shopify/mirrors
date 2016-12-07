module Mirrors
  module PackageInference
    class ClassToFileResolver
      def initialize
        @files = {}
      end

      # @param [ClassMirror] cm
      # @return [String, nil]
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
        cm.instance_methods.each do |mm|
          file = mm.file
          next unless file

          contents = (@files[file] ||= File.open(file, 'r') { |f| f.readpartial(4096) })
          pat = /^\s+(class|module) ([\S]+::)?#{Regexp.quote(demodulized_name)}\s/
          return file if contents =~ pat
        end
        nil
      end

      def try_slow(cm)
        defined_directly_on_class = cm.instance_methods
          .select do |mm|
            # as a mostly-useful heuristic, we just eliminate everything that was
            # defined using a template eval or define_method.
            src = mm.source
            src && src =~ /\A\s+def (self\.)?#{Regexp.quote(mm.name)}/
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
