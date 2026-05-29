class FileHandlers::F3d < FileHandlers::Base
  ENVIRONMENTS = [:server].freeze
  INPUT_TYPES = `f3d --list-readers`.lines
    .filter_map { |it| it.match(/\w[a-z]*\/[0-9a-z.+-]*\w/)&.to_s }
    .filter_map { |it| Mime::Type.lookup(it) }
    .uniq
    .freeze
end
