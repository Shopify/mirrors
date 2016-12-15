module Mirrors
  module ApplicationPackageSupport
    @memo_package = {}
    @memo_private = {}

    ConflictingPackageTags = Class.new(StandardError)

    # Find the package for a class/module from a line in the docstring
    # before some location where the class is opened of the form
    # +# @package foo+.
    #
    # @param [ClassMirror] class_mirror class to search for package of
    # @return [String,nil] package name, if any.
    def package(class_mirror)
      if hit = @memo_package[class_mirror]
        return hit == :cached_nil ? nil : hit
      end

      found = []
      class_mirror.nesting.each do |cm|
        next unless ranges = Mirrors::Init.definition_ranges(cm.name)
        ranges.each do |_, file, startline, _|
          if pkg = tag_for_block("@package", file, startline)
            found << Package.new(pkg)
          end
        end
      end

      found.uniq!
      if found.size > 1
        raise ConflictingPackageTags,
          "#{class_mirror.name} has conflicting packages: #{found.join(', ')}"
      end
      pkg = found.first

      @memo_package[class_mirror] = pkg ? pkg : :cached_nil
      pkg
    end
    module_function :package

    # Test whether a class or module is private to the package it was
    # defined in. If not in a package, this return false. If in a package, but
    # lacking an +@export+ comment, return false. If an +@export+ comment is
    # given, it must match the name of the class. If the class is the toplevel
    # of the package, it is exported by default.
    #
    # @example
    #   # @package my-package
    #   class Foo
    #     # @export Bar
    #     class Bar
    #     end
    #     class Baz
    #     end
    #   end
    #   Mirrors.reflect(Foo).private? # => false
    #   Mirrors.reflect(Foo::Bar).private? # => false
    #   Mirrors.reflect(Foo::Baz).private? # => true
    #
    # @param [ClassMirror] class_mirror class to test visibility of
    # @return [Boolean]
    def private?(class_mirror)
      unless (hit = @memo_private[class_mirror]).nil?
        return hit
      end

      unless package(class_mirror)
        return @memo_private[class_mirror] = false
      end

      ranges = Mirrors::Init.definition_ranges(class_mirror.name)
      unless ranges # true? false? what makes more sense?
        return @memo_private[class_mirror] = true
      end

      ranges.each do |_, file, startline, _|
        if tag_for_block("@package", file, startline) || tag_for_block("@export", file, startline)
          return @memo_private[class_mirror] = false
        end
      end

      @memo_private[class_mirror] = true
    end
    module_function :private?

    # @param [ClassMirror] this class from which the other constant is being
    #   accessed
    # @param [ClassMirror] class being accessed
    # @return [Boolean]
    def visible_from?(this, other)
      priv = private?(this)
      return true unless priv
      otherpkg = package(other)
      return true unless otherpkg
      otherpkg == package(this)
    end
    module_function :visible_from?

    # This could obviously be done way less stupidly.
    def self.tag_for_block(tag, file, startline)
      lines = File.readlines(file)
      lines[0...startline - 1].reverse.detect do |line|
        break unless line =~ /^\s*#/
        if md = line.match(/# #{tag} (\S+)/)
          return md[1]
        end
      end
      nil
    end
    private_class_method :tag_for_block
  end
end
