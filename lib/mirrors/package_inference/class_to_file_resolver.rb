module Mirrors
  module PackageInference
    class ClassToFileResolver
      def initialize
        @files = {}
      end

      def resolve(klass)
        return nil if klass.nil?

        name = begin
          Mirrors.rebind(Module, klass, :name).call
        rescue TypeError
          # klass is not a class/module, so we can't really determine its
          # origin.
          return nil
        end

        try_fast(klass, name)                   ||
          try_fast(klass.singleton_class, name) ||
          try_slow(klass)                       ||
          try_slow(klass.singleton_class)
      end

      private

      def try_fast(klass, class_name)
        klass.instance_methods(false).each do |name|
          meth = klass.instance_method(name)

          file = begin
            sl = meth.source_location
            next unless sl
            sl[0]
          rescue MethodSource::SourceNotFoundError
            next
          end

          contents = (@files[file] ||= File.open(file, 'r') { |f| f.readpartial(4096) })
          n = class_name.sub(/.*::/, '') # last component of module name
          return file if contents =~ /^\s+(class|module) ([\S]+::)?#{Regexp.quote(n)}\s/
        end
        nil
      end

      def try_slow(klass)
        methods = klass
          .instance_methods(false)
          .map { |n| klass.instance_method(n) }

        defined_directly_on_class = methods
          .select do |meth|
            # as a mostly-useful heuristic, we just eliminate everything that was
            # defined using a template eval or define_method.
            begin
              meth.source =~ /\A\s+def (self\.)?#{Regexp.quote(meth.name)}/
            rescue MethodSource::SourceNotFoundError
              false
            rescue NoMethodError => e
              STDERR.puts "\x1b[31mbug in method_source for #{meth}: #{e.inspect}\x1b[0m"
              false
            end
          end

        files = Hash.new(0)

        defined_directly_on_class.each do |meth|
          begin
            sl = meth.source_location[0]
            raise unless sl
            files[sl[0]] += 1
          rescue MethodSource::SourceNotFoundError
            raise
          end
        end

        file = files.max_by { |_k, v| v }
        file ? file[0] : nil
      end
    end
  end
end
