class Components::Renderers::IframeTag < Components::Base
  def self.supports?(file)
    FileHandlers::IframeTag.can_load? file&.mime_type
  end

  def initialize(file:)
    @file = file
  end

  def view_template
    iframe(
      src: model_model_file_raw_path(@file.model, @file.filename),
      alt: @file.name,
      style: "width: 100%; aspect-ratio: 0.707"
    )
  end
end
