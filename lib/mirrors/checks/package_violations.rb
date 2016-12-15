require 'mirrors'

module Mirrors
  module Checks
    class PackageViolations
      def self.check
        unless defined?(Mirrors::Init)
          raise "can't use this check unless you loaded Mirrors::Init at program start"
        end

        error_markers = []
        Mirrors.files.each do |fm|
          fm.references.each do |marker|
            next unless ret = Mirrors::ApplicationPackageSupport.marker_in_violation?(marker)
            this, other = ret
            error_markers << Mirrors::Marker.new(
              type: Mirrors::Marker::TYPE_PROBLEM,
              message: "Invalid cross-package access (#{this.name} -> #{other.name})",
              line: marker.line,
            )
          end
        end

        error_markers.empty? ? nil : error_markers
      end
    end
  end
end
