require 'mirrors/mirror'
require 'mirrors/package_inference'

module Mirrors
  class PackageMirror < Mirror
    def self.reflect(name)
      new(name)
    end

    def name
      @reflectee.sub(/.*:/, '')
    end

    def fullname
      @reflectee
    end

    def children
      names = PackageInference.contents_of_package(@reflectee)
      classes = (names || [])
        .map { |n| Object.const_get(n) }
        .select { |c| c.is_a?(Module) }
        .sort_by(&:name)
      class_mirrors = mirrors(classes)

      # .map    { |pkg| pkg.sub(/#{Regexp.quote(@reflectee)}:.*?:.*/) }
      subpackages = PackageInference.qualified_packages
        .select { |pkg| pkg.start_with?("#{@reflectee}:") }
        .sort

      puts subpackages.inspect

      package_mirrors = subpackages.map { |pkg| PackageMirror.reflect(pkg) }
      package_mirrors.concat(class_mirrors)
    end
  end
end
