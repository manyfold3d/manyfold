class FileHandlers::ImageMagick < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.imagemagick")

  def self.readers
    `magick -list format`
  end

  def self.priority
    2000
  end

  ENVIRONMENTS = [:thumbnail].freeze
  INPUT_TYPES = readers.lines
    .filter_map { it.match(/^\s*(?<format>[A-Z]{2,})/) }
    .filter_map { it[:format].downcase.to_sym }
    .filter_map { Mime[it] }
    .filter { it.in? MediaType.image_types.without(Mime[:svg]) }
    .uniq
    .freeze
end
