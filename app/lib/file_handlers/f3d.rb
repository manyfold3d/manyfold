class FileHandlers::F3d < FileHandlers::Base
  def self.readers
    `f3d --list-readers`
  end

  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = readers.lines
    .filter_map { it.match(/\w[a-z]*\/[0-9a-z.+-]*\w/)&.to_s }
    .filter_map { Mime::Type.lookup(it) }
    .uniq
    .freeze
end
