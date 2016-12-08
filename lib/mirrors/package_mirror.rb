require 'mirrors/mirror'
require 'mirrors/package_inference'

module Mirrors
  # A mirror for our pretend {Package} object that bolts a semblance of a
  # package system on top of ruby.
  class PackageMirror < Mirror
    # @example
    #   Mirrors.reflect(Package.new('gems:minitest')).qualified_name
    #   #=> 'minitest'
    # @see qualified_name
    # @return [String] the abbreviated name, excluding namespace
    def name
      @reflectee.name.sub(/.*:/, '')
    end

    # @example
    #   Mirrors.reflect(Package.new('gems:minitest')).qualified_name
    #   #=> 'gems:minitest'
    # @see name
    # @return [String] the full name, including namespace
    def qualified_name
      @reflectee.name
    end

    # @example
    #   Mirrors.reflect(Mirrors::Package.new("a:b")).parent #=> #<PM:a>
    #   Mirrors.reflect(Mirrors::Package.new("abc")).parent #=> nil
    # @return [PackageMirror,nil] The package one level up, if any.
    def parent
      n = @reflectee.name.sub(/:[^:]+$/, '')
      return nil if n == @reflectee.name
      Mirrors.reflect(Package.new(n))
    end

    # @see contents
    # @see parent
    # @return [Array<PackageMirror>] subpackages
    def children
      subpackages = PackageInference.qualified_packages
        .select { |pkg| pkg.start_with?("#{@reflectee.name}:") }
        .sort
      mirrors(subpackages)
    end

    # @see children
    # @return [Array<ClassMirror>] classes/modules belonging to this package
    def contents
      names = PackageInference.contents_of_package(@reflectee)
      classes = (names || [])
        .map { |n| Object.const_get(n) }
        .select { |c| c.is_a?(Module) }
        .sort_by(&:name)
      mirrors(classes)
    end

    # @example
    #   Mirrors.reflect(Mirrors::Package.new("a:b")).nesting
    #   #=> [#<PM:a:b>, #<PM:a>]
    # @return [Array<PackageMirror>] The full package nesting.
    def nesting
      components = @reflectee
        .name       # 'a:b:c'
        .split(':') # ['a', 'b', 'c']
      components
        .size                                   # 3
        .times                                  # #<Enumerator>
        .map { |i| components[0..i].join(':') } # ['a', 'a:b', 'a:b:c']
        .reverse                                # ['a:b:c', 'a:b', 'a']
        .map { |n| Mirrors.reflect(Package.new(n)) }
    end
  end
end
