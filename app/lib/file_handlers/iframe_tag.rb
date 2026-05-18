class FileHandlers::IframeTag < FileHandlers::Base
  class << self
    def environments
      [:browser]
    end

    def component
      Components::Renderers::IframeTag
    end

    def input_types
      SupportedMimeTypes.document_types
    end
  end
end
