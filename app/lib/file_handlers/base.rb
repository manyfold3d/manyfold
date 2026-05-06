class FileHandlers::Base
  class << self
    extend Memoist

    def can_load?(type)
      type.in? input_types
    end
    memoize :can_load?

    def input_types
      []
    end
    memoize :input_types

    def can_save?(type)
      type.in? output_types
    end
    memoize :can_save?

    def output_types
      []
    end
    memoize :output_types
  end
end
