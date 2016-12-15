module Mirrors
  module ApplicationPackageSupport
    # Find the package for a class/module from a line in the docstring
    # before some location where the class is opened of the form
    # +# @package foo+.
    #
    # @todo continue recursing even when a match is found and conflict if
    #   multiple packages are specified.
    # @todo if conflicting packages are specified at different definition
    #   sites, fail.
    # @todo memoize, but make sure to cache nils
    #
    # @param [ClassMirror] class_mirror class to search for package of
    # @return [String,nil] package name, if any.
    def package(class_mirror)
      class_mirror.nesting.each do |cm|
        next unless ranges = Mirrors::Init.definition_ranges(cm.name)
        ranges.each do |file, startline, _|
          if pkg = tag_for_block("@package", file, startline)
            return Package.new(pkg)
          end
        end
      end
      nil
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
    # @todo verify the name specified in the export comment
    # @todo memoize, but make sure to cache false
    #
    # @param [ClassMirror] class_mirror class to test visibility of
    # @return [Boolean]
    def private?(class_mirror)
      return false unless package(class_mirror)

      ranges = Mirrors::Init.definition_ranges(class_mirror.name)
      return true unless ranges # true? false? what makes more sense?

      ranges.each do |file, startline, _|
        return false if tag_for_block("@package", file, startline)
        return false if tag_for_block("@export", file, startline)
      end

      true
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
