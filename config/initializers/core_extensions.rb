# Mixing in some extensions to core classes
require "trim_path_separators"

class String
  include TrimPathSeparators
end
