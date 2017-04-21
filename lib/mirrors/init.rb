# if we enable the tracepoint inside a class body, we'd have to prepopulate the
# stack to handle the :end events. So we just assign it in the root lexical
# context, having already created the modules.
module Mirrors
  module Init
    @classdefs = {}
    @classes_by_file = {}
  end
end

# Immediately activated upon load of +mirrors/init+. Observes class/module
# definition.
Mirrors::Init::CLASS_DEFINITION_TRACEPOINT = begin
  # we don't use +Mirrors.rebind+ for this because we don't want to load any
  # more code than is necessary before the +TracePoint+ is enabled.
  name = Module.instance_method(:inspect)
  stack = []
  classdefs       = Mirrors::Init.instance_variable_get(:@classdefs)
  classes_by_file = Mirrors::Init.instance_variable_get(:@classes_by_file)
  TracePoint.new(:class, :end) do |tp|
    if tp.event == :class
      klass = tp.self
      entry = if klass.singleton_class?
        :singleton
      else
        [name.bind(klass).call, tp.path, tp.lineno, -1]
      end
      stack << entry
    else # :end
      entry = stack.pop
      unless entry == :singleton
        cname = entry[0]     # [class_name, file, start_line, -1]
        file = entry[1]
        entry[3] = tp.lineno # [class_name, file, start_line, end_line]
        classdefs[cname] ||= []
        classdefs[cname] << entry
        classes_by_file[file] ||= []
        classes_by_file[file] << entry
      end
    end
  end.tap(&:enable)
end

module Mirrors
  # Registers a TracePoint immediately upon load to track points at which
  # classes and modules are opened for definition. This is used to track
  # correspondence between classes/modules and files, as this information isn't
  # available in the ruby runtime without extra accounting.
  module Init
    # Returns the files in which this class or module was opened. Doesn't know
    # about situations where the class was opened prior to +require+ing
    # +mirrors/init+, or where metaprogramming was used via +eval+, etc.
    #
    # @param  [String,Module] klass The class/module, or its +#name+
    # @return [Array<(String, Integer, Integer)>,nil] set of filenames, or nil if none recorded.
    def class_files(klass)
      name = case klass
      when String
        klass
      else
        Mirrors.rebind(Module, klass, :inspect).call
      end
      if cds = @classdefs[name]
        ret = cds.map { |e| e[1] }
        ret.uniq!
        ret
      end
    end
    module_function :class_files

    # Returns the files with line-ranges in which this class or module was
    # opened. Doesn't know about situations where the class was opened prior to
    # +require+ing +mirrors/init+, or where metaprogramming was used via
    # +eval+, etc. The format is +[file path, start lineno, end lineno]+
    #
    # @param  [String,Module] klass The class/module, or its +#name+
    # @return [Array<(String, Integer, Integer)>,nil] list of files with
    #   line-ranges in which this class was opened, if any known.
    def definition_ranges(klass)
      name = case klass
      when String
        klass
      else
        Mirrors.rebind(Module, klass, :inspect).call
      end
      @classdefs[name]
    end
    module_function :definition_ranges

    def class_enclosing(file, lineno)
      return unless ranges = @classes_by_file[file]
      best_line = -1
      best_name = nil
      ranges.each do |name, _, start_line, end_line|
        if lineno >= start_line && lineno <= end_line && start_line > best_line
          best_line = start_line
          best_name = name
        end
      end
      return unless best_name
      const = best_name.split('::').inject(Object) { |m, c| m.const_get(c) }
      Mirrors.reflect(const)
    end
    module_function :class_enclosing
  end
end
