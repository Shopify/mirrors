class Resolver
  def resolve(klass)
    @files ||= {}

    klass.instance_methods(false).each do |name|
      meth = klass.instance_method(name)

      file = begin
        meth.source_location[0]
      rescue # ???
        next
      end

      contents = (@files[file] ||= File.open(file, 'r') { |f| f.readpartial(4096) })
      n = klass.name.sub(/.*::/, '') # last component of module name
      return file if contents =~ /^\s+(class|module) ([\S]+::)?#{Regexp.quote(n)}\s/
    end
    nil
  end
end

def infer_class_file_from_methods(klass)
  if m = Resolver.new.resolve(klass)
    return m
  end

  methods = klass
    .instance_methods(false)
    .map { |n| klass.instance_method(n) }

  defined_directly_on_class = methods
    .select do |meth|
      # aliased methods can show up with instance_methods(false)
      # but their source_location and owner point to the module they came from.
      meth.owner == klass &&
        meth.source =~ /\A\s+def #{Regexp.quote(meth.name)}/
      # as a mostly-useful heuristic, we just eliminate everything that was
      # defined using a template eval or define_method.
    end

  files = Hash.new(0)

  defined_directly_on_class.each do |meth|
    begin
      files[meth.source_location[0]] += 1
    rescue # which class?
      raise
    end
  end

  file = files.max_by { |k, v| v }
  file ? file[0] : nil
end
