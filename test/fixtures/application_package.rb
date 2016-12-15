module NoPackage
  module A
  end
end

# @package export-a
module ExportA
  # @export
  module A
  end

  module B
  end
end

# @package no-export-a
module NoExportA
  module A
  end

  module B
  end
end

module NotToplevel
  # @package not-toplevel
  module A
  end
end

# @package nested-1
module Nested
  # @package nested-2
  module A
  end
end

module Conflict
  # @package conflict-1
  module A
  end

  # @package conflict-2
  module A
  end
end
