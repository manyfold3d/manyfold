# Mixing in some extensions to core classes
require "trim_path_separators"
require "locale_awareness"
require "careful_titleize"

class String
  include TrimPathSeparators
  include LocaleAwareness
  include CarefulTitleize
end
