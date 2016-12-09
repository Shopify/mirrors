module Mirrors
  # Simple class to represent a "package" in a ruby program. These are
  # heuristically assigned to modules based on file path
  #
  # @see PackageInference
  # @see PackageMirror
  Package = Struct.new(:name)
end
