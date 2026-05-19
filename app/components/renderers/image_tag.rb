class Components::Renderers::ImageTag < Components::Renderers::Base
  def self.supports?(file)
    FileHandlers::ImageTag.can_load? file&.mime_type
  end

  def view_template
    img(
      src: model_model_file_raw_path(@file.model, @file.filename),
      alt: @file.name,
      style: "width: 100%"
    )
  end
end
