module Mirrors
  # Simple class to represent a "package" in a ruby program. These are
  # heuristically assigned to modules based on file path
  #
  # @see PackageInference
  # @see PackageMirror
  #
  # @!attribute [r] name
  #   @return [String] the name of the package
  class Package
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
