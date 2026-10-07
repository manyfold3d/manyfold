class FileHandlers::ImageTag < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.image_tag")

  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = MediaType.image_types.without([Mime[:bmp], Mime[:tiff]])

  def self.component
    Components::Renderers::ImageTag
  end
end
