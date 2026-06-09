class FileHandlers::F3d < FileHandlers::Base
  def self.readers
    `f3d --list-readers`
  end

  ENVIRONMENTS = [:browser, :preview_frame, :server].freeze
  INPUT_TYPES = readers.lines
    .filter_map { |it| it.match(/\w[a-z]*\/[0-9a-z.+-]*\w/)&.to_s }
    .filter_map { |it| Mime::Type.lookup(it) }
    .uniq
    .freeze

  def self.component
    Components::Renderers::F3d
  end
end
