class FileHandlers::VideoTag < FileHandlers::Base
  class << self
    def environments
      [:browser]
    end

    def component
      Components::Renderers::VideoTag
    end

    def input_types
      SupportedMimeTypes.video_types
    end
  end
end
