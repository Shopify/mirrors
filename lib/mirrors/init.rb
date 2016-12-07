require 'set'

module Mirrors
  # Registers a TracePoint immediately upon load to track points at which
  # classes and modules are opened for definition. This is used to track
  # correspondence between classes/modules and files, as this information isn't
  # available in the ruby runtime without extra accounting.
  module Init
    @class_files = {}

    # we don't use +Mirrors.rebind+ for this because we don't want to load any
    # more code than is necessary before the +TracePoint+ is enabled.
    name = Module.instance_method(:inspect)

    # Immediately activated upon load of +mirrors/init+. Observes class/module
    # definition.
    CLASS_DEFINITION_TRACEPOINT = TracePoint.new(:class) do |tp|
      unless tp.self.singleton_class?
        key = name.bind(tp.self).call
        @class_files[key] ||= Set.new
        @class_files[key] << tp.path
      end
    end.tap(&:enable)

    # Returns the files in which this class or module was opened. Doesn't know
    # about situations where the class was opened prior to +require+ing
    # +mirrors/init+, or where metaprogramming was used via +eval+, etc.
    #
    # @param  [String,Module] klass The class/module, or its +#name+
    # @return [Set<String>,nil] set of filenames, or nil if none recorded.
    def class_files(klass)
      case klass
      when String
        @class_files[klass]
      else
        name = Mirrors.rebind(Module, klass, :inspect).call
        @class_files[name]
      end
    end
    module_function :class_files
  end
end
