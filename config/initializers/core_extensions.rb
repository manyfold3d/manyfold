# Mixing in some extensions to core classes
require "trim_path_separators"
require "locale_awareness"

class String
  include TrimPathSeparators
  include LocaleAwareness
end
