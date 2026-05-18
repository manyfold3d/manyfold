class FileHandlers::IframeTag < FileHandlers::Base
  class << self
    def environments
      [:browser]
    end

    def priority
      200
    end

    def component
      Components::Renderers::IframeTag
    end

    def input_types
      Mime::EXTENSION_LOOKUP.slice("pdf", "html", "text", "md").values
    end
  end
end
