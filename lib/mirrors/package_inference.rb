require 'rbconfig'
require 'set'

require 'mirrors/package_inference/class_to_file_resolver'

module Mirrors
  module PackageInference
    extend self

    def infer_from(mod, resolver = ClassToFileResolver.new)
      insp = Mirrors.rebind(Module, mod, :inspect).call
      infer_from_key(insp, resolver)
    end

    def infer_from_toplevel(sym, resolver = ClassToFileResolver.new)
      infer_from_key(sym.to_s, resolver)
    end

    def contents_of_package(pkg)
      @inverse_cache[pkg]
    end

    def qualified_packages
      @inverse_cache.keys
    end

    private

    def infer_from_key(key, resolver)
      @inference_cache ||= {}
      @inverse_cache ||= {}

      cached = @inference_cache[key]
      return cached if cached

      pkg = uncached_infer_from(key, [], resolver)
      @inference_cache[key] = pkg
      @inverse_cache[pkg] ||= []
      @inverse_cache[pkg] << key

      pkg
    end

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

    CORE_PACKAGE         = 'core'.freeze
    CORE_STDLIB_PACKAGE  = 'core:stdlib'.freeze
    APPLICATION_PACKAGE  = 'application'.freeze
    GEM_PACKAGE_PREFIX   = 'gems:'.freeze
    UNKNOWN_PACKAGE      = 'unknown'.freeze
    UNKNOWN_EVAL_PACKAGE = 'unknown:eval'.freeze

    def uncached_infer_from(key, exclusions, resolver)
      return CORE_PACKAGE if CORE.include?(nesting_first(key))

      filename = determine_filename(key, resolver)

      if filename.nil?
        return try_harder(key, exclusions, resolver)
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
            return GEM_PACKAGE_PREFIX + md[1]
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
            return GEM_PACKAGE_PREFIX + md[1]
          end
        end
      end
      nil
    end

    def determine_filename(key, resolver)
      raw = Object.const_get(key)
      return nil unless raw.is_a?(Module)

      resolver.resolve(Mirrors.reflect(raw))
    end

    def try_harder(key, exclusions, resolver)
      obj = Object.const_get(key)
      return 'unknown' unless obj.is_a?(Module)
      exclusions << obj

      obj.constants.each do |const|
        child = obj.const_get(const)
        next unless child.is_a?(Module)

        next if exclusions.include?(child)

        insp = Mirrors.rebind(Module, child, :inspect).call
        pkg = uncached_infer_from(insp, exclusions, resolver)
        return pkg unless pkg == 'unknown'
      end

      'unknown'
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
