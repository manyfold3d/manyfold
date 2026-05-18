class FileHandlers::ImageTag < FileHandlers::Base
  class << self
    def environments
      [:browser]
    end

    def component
      Components::Renderers::ImageTag
    end

    def input_types
      SupportedMimeTypes.image_types
    end
  end
end
