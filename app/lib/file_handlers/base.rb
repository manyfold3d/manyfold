class FileHandlers::Base
  # Derived classes should set the ENVIRONMENTS constant to an array of places that this handler applies to.
  # Any of:
  #  :server (the thing running Manyfold)
  #  :browser (the visitor's web browser - Safari, Chrome, etc)
  #  :preview_frame (like browser, but specifically for use inside a PreviewFrame component)
  #  :client (the visitor's machine, that the browser is running on)
  # ENVIRONMENTS = [].freeze

  # Derived classes should set the INPUT_TYPES constant to an array of mime types that this handler can load (if any)
  # INPUT_TYPES = [].freeze

  # Derived classes should set the OUTPUT_TYPES constant to an array of mime types that this handler can save (if any)
  # OUTPUT_TYPES = [].freeze

  class << self
    prepend MemoWise

    def priority
      0
    end

    def icon
      nil
    end

    # For test mocking only
    def input_types
      self::INPUT_TYPES
    end

    def can_load?(type)
      case type.class.name
      when "String"
        type.in? self::INPUT_TYPES.filter_map(&:to_s)
      when "Symbol"
        type.in? self::INPUT_TYPES.filter_map(&:to_sym)
      else
        type.in? self::INPUT_TYPES
      end
    end
    memo_wise :can_load?

    # For test mocking only
    def output_types
      OUTPUT_TYPES
    end

    def can_save?(type)
      case type.class.name
      when "String"
        type.in? self::OUTPUT_TYPES.filter_map(&:to_s)
      when "Symbol"
        type.in? self::OUTPUT_TYPES.filter_map(&:to_sym)
      else
        type.in? self::OUTPUT_TYPES
      end
    end
    memo_wise :can_save?

    def open_url_for(target_url, client_os: nil)
      raise NotImplementedError
    end
  end
end
