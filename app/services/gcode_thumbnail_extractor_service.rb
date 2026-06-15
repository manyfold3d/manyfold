class GcodeThumbnailExtractorService
  def initialize(file:)
    @file = file
  end

  def call
    match = @file.read.match(/thumbnail[^\n]*begin[^\n]*?([0-9]+)\n(.*?)thumbnail[^\n]*end/m)
    return unless match
    length = match[1].to_i
    encoded = match[2].gsub(/[;\s]/, "")
    return unless encoded.length == length
    StringIO.new(Base64.strict_decode64(encoded))
  rescue
    nil
  end
end
