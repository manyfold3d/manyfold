class FileHandlers::FreecadThumbnailExtractor < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.freecad_thumbnail_extractor")

  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = [Mime[:fcstd]].freeze
end
