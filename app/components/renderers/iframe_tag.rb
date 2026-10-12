module Components::Renderers
  class IframeTag < Components::Renderers::Base
    def self.supports?(file)
      FileHandlers::IframeTag.can_load? file&.mime_type
    end

    def view_template
      iframe(
        src: model_model_file_raw_path(@file.model, @file.filename),
        alt: @file.name,
        style: "width: 100%; aspect-ratio: 0.707",
        sandbox: (@file.mime_type == Mime[:pdf]) ? nil : safe("") # Don't need to sandbox PDFs apparently
      )
    end
  end
end
