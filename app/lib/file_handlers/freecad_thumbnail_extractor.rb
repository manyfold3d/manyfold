class FileHandlers::FreecadThumbnailExtractor < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.freecad_thumbnail_extractor")

  ENVIRONMENTS = [:thumbnail].freeze
  INPUT_TYPES = [Mime[:fcstd]].freeze

  def self.thumbnailer
    FreecadThumbnailExtractorService
  end
end
