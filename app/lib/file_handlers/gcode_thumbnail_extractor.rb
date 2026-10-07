class FileHandlers::GcodeThumbnailExtractor < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.gcode_thumbnail_extractor")

  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = [Mime[:gcode]].freeze
end
