class FileHandlers::FreecadThumbnailExtractor < FileHandlers::Base
  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = [Mime[:fcstd]].freeze
end
