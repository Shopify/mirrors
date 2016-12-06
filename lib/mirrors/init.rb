require 'set'

module Mirrors
  module Init
    @class_files = {}

    name = Module.instance_method(:inspect)

    CLASS_DEFINITION_TRACEPOINT = TracePoint.new(:class) do |tp|
      unless tp.self.singleton_class?
        key = name.bind(tp.self).call
        @class_files[key] ||= Set.new
        @class_files[key] << tp.path
      end
    end.tap(&:enable)

    def class_files(key)
      @class_files[key]
    end
    module_function :class_files
  end
end
