require 'rbconfig'
require 'set'

require 'mirrors/package'
require 'mirrors/package_inference/class_to_file_resolver'

module Mirrors
  # Infers "packages" from a given module or constant. Since ruby doesn't
  # actually support any sort of package system, this is all just heuristic
  # based on filename and a few other minor assumptions.
  #
  # In general, we try to separate application code from stdlib and gems.
  #
  # Packages are a pretend construct that we're bolting on top of
  # what's actually supported by ruby (so far), so the extent of this
  # currently is to make some decisions based on the file path.
  module PackageInference
    class << self
      # Determines a package name for the given module.
      #
      # @param [ClassMirror] mod the class/module for which to determine the package.
      # @param [ClassToFileResolver] resolver caches some data internally, so if you're
      #   going to call +infer_from+ many times, it's useful to provide one.
      # @return [PackageMirror] The package of the given module
      def infer_from(mod, resolver = ClassToFileResolver.new)
        @inference_cache ||= {}
        @inverse_cache ||= {}

        key = mod.name

        cached = @inference_cache[key]
        return cached if cached

        pkg = uncached_infer_from(mod, [], resolver)
        @inference_cache[key] = pkg
        @inverse_cache[pkg.name] ||= []
        @inverse_cache[pkg.name] << mod

        Mirrors.reflect(pkg)
      end

      # @param [String] pkg the name of the package to look up
      # @return [Array<ClassMirror>] All the items sorted into +pkg+ so far.
      def contents_of_package(pkg)
        (@inverse_cache || {})[pkg.name]
      end

      # @return [Array<String>] All the packages that have been determined to
      #   exist so far.
      def qualified_packages
        (@inverse_cache || {}).keys.map { |n| Package.new(n) }
      end

      private

      # ruby --disable-gems -e 'puts Object.constants'
      CORE = Set.new(%w(
        Object Module Class BasicObject Kernel NilClass NIL Data TrueClass TRUE
        FalseClass FALSE Encoding Comparable Enumerable String Symbol Exception
        SystemExit SignalException Interrupt StandardError TypeError
        ArgumentError IndexError KeyError RangeError ScriptError SyntaxError
        LoadError NotImplementedError NameError NoMethodError RuntimeError
        SecurityError NoMemoryError EncodingError SystemCallError Errno
        UncaughtThrowError ZeroDivisionError FloatDomainError Numeric Integer
        Fixnum Float Bignum Array Hash ENV Struct RegexpError Regexp MatchData
        Marshal Range IOError EOFError IO STDIN STDOUT STDERR ARGF FileTest File
        Dir Time Random Signal Proc LocalJumpError SystemStackError Method
        UnboundMethod Binding Math GC ObjectSpace Enumerator StopIteration
        RubyVM Thread TOPLEVEL_BINDING ThreadGroup ThreadError ClosedQueueError
        Mutex Queue SizedQueue ConditionVariable Process Fiber FiberError
        Rational Complex RUBY_VERSION RUBY_RELEASE_DATE RUBY_PLATFORM
        RUBY_PATCHLEVEL RUBY_REVISION RUBY_DESCRIPTION RUBY_COPYRIGHT
        RUBY_ENGINE RUBY_ENGINE_VERSION TracePoint ARGV DidYouMean
      )).freeze

      CORE_PACKAGE         = Package.new('core'.freeze)
      CORE_STDLIB_PACKAGE  = Package.new('core:stdlib'.freeze)
      APPLICATION_PACKAGE  = Package.new('application'.freeze)
      UNKNOWN_PACKAGE      = Package.new('unknown'.freeze)
      UNKNOWN_EVAL_PACKAGE = Package.new('unknown:eval'.freeze)
      GEM_PACKAGE_PREFIX   = 'gems:'.freeze

      def uncached_infer_from(mod, exclusions, resolver)
        return CORE_PACKAGE if CORE.include?(nesting_first(mod.name))

        filename = mod.file(resolver)

        if filename.nil?
          return try_harder(mod, exclusions, resolver)
        end

        return APPLICATION_PACKAGE if filename.start_with?(Mirrors.project_root)
        return CORE_STDLIB_PACKAGE if filename.start_with?(rubylibdir)

        if pkg = try_rubygems(filename)
          return pkg
        end

        if pkg = try_bundler(filename)
          return pkg
        end

        return UNKNOWN_EVAL_PACKAGE if filename == '(eval)'

        UNKNOWN_PACKAGE
      end

      def try_rubygems(filename)
        if defined?(Gem)
          gem_path.each do |path|
            next unless filename.start_with?(path)
            # extract e.g. 'bundler-1.13.6'
            gem_with_version = filename[path.size..-1].sub(%r{/.*}, '')
            if md = gem_with_version.match(/(.*)-(\d|[a-f0-9]+$)/)
              return Package.new(GEM_PACKAGE_PREFIX + md[1])
            end
          end
        end
        nil
      end

      def try_bundler(filename)
        if defined?(Bundler)
          path = bundle_path
          if filename.start_with?(path)
            gem_with_version = filename[path.size..-1].sub(%r{/.*}, '')
            if md = gem_with_version.match(/(.*)-(\d|[a-f0-9]+$)/)
              return Package.new(GEM_PACKAGE_PREFIX + md[1])
            end
          end
        end
        nil
      end

      def try_harder(mod, exclusions, resolver)
        exclusions << mod

        mod.nested_classes.each do |child|
          next if exclusions.include?(child)
          pkg = uncached_infer_from(child, exclusions, resolver)
          return pkg unless pkg == UNKNOWN_PACKAGE
        end

        UNKNOWN_PACKAGE
      end

      def nesting_first(n)
        n.sub(/::.*/, '')
      end

      def rubylibdir
        @rubylibdir ||= RbConfig::CONFIG['rubylibdir']
      end

      def gem_path
        @gem_path ||= Gem.path.map { |p| "#{p}/gems/" }
      end

      def bundle_path
        @bundle_path ||= "#{Bundler.bundle_path}/bundler/gems/"
      end
    end
  end
end
