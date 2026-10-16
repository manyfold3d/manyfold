class FileHandlers::VideoTag < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.video_tag")

  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = MediaType.video_types.freeze

  def self.component
    Components::Renderers::VideoTag
  end
end
