class FileHandlers::Base
  # Derived classes should set the ENVIRONMENTS constant to an array of places that this handler applies to.
  # Any of:
  #  :server (the thing running Manyfold)
  #  :browser (the visitor's web browser - Safari, Chrome, etc)
  #  :preview_frame (like browser, but specifically for use inside a PreviewFrame component)
  #  :client (the visitor's machine, that the browser is running on)
  ENVIRONMENTS = [].freeze

  # Derived classes should set the INPUT_TYPES constant to an array of mime types that this handler can load (if any)
  INPUT_TYPES = [].freeze

  # Derived classes should set the OUTPUT_TYPES constant to an array of mime types that this handler can save (if any)
  OUTPUT_TYPES = [].freeze

  class << self
    extend Memoist

    def priority
      0
    end

    def can_load?(type)
      Rails.logger.warn "#{class_name}#can_load? #{type}"
      type.in? INPUT_TYPES
    end
    memoize :can_load?

    def can_save?(type)
      type.in? OUTPUT_TYPES
    end
    memoize :can_save?

    def open_url_for(target_url, client_os: nil)
      raise NotImplementedError
    end
  end
end
