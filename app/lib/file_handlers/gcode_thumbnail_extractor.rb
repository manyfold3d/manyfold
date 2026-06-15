class FileHandlers::GcodeThumbnailExtractor < FileHandlers::Base
  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = [Mime[:gcode]].freeze
end
