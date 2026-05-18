class FileHandlers::Base
  class << self
    extend Memoist

    def priority
      0
    end

    def environments
      # Derived classes should return an array of places that this handler applies to.
      # Any of:
      #  :server (the thing running Manyfold)
      #  :browser (the visitor's web browser - Safari, Chrome, etc)
      #  :client (the visitor's machine, that the browser is running on)
      []
    end

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

    def open_url_for(target_url, client_os: nil)
      raise NotImplementedError
    end

    def handlers_for(environment:, load_file:)
      FileHandlers.constants
        .map { |it| FileHandlers.const_get(it) }
        .sort { |a, b| b&.priority <=> a&.priority }
        .select { |it| it.environments.include? environment }
        .select { |it| it.can_load? Mime[load_file.mime_type] }
    end
  end
end
