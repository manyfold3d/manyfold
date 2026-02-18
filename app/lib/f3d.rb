module F3d
  def self.readers
    `f3d --list-readers`.lines
  end

  def self.reader_mime_types
    readers.filter_map { |it| it.match(/\w[a-z]*\/[0-9a-z.+-]*\w/)&.to_s }
  end
end
