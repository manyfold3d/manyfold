module Components::Renderers
  class VideoTag < Components::Renderers::Base
    def self.supports?(file)
      FileHandlers::VideoTag.can_load? file&.mime_type
    end

    def view_template
      video(
        src: model_model_file_raw_path(@file.model, @file.filename),
        alt: @file.name,
        style: "width: 100%",
        controls: true
      )
    end
  end
end
