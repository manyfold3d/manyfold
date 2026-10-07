class FreecadThumbnailExtractorService
  def initialize(file:, record:)
    @file = file
    @record = record
  end

  def call
    thumbnail = nil
    Archive::Reader.open_filename(@file.path) do |reader|
      reader.each_entry do |entry|
        next unless entry.pathname == "thumbnails/Thumbnail.png"
        Dir.mktmpdir do |dir|
          reader.extract(entry, Archive::EXTRACT_SECURE, destination: dir)
          thumbnail = File.read(File.join(dir, "thumbnails/Thumbnail.png"))
        end
      end
    end
    thumbnail ? {render: StringIO.new(thumbnail)} : {}
  end
end
