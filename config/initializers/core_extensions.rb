# Mixing in some extensions to core classes
class String
  include TrimPathSeparators
  include LocaleAwareness
  include CarefulTitleize
end
