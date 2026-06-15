class GcodeThumbnailExtractorService
  def initialize(file:)
    @file = file
  end

  def call
    match = @file.read.match(/thumbnail[^\n]*begin[^\n]*\n(.*?)thumbnail[^\n]*end/m)
    return unless match
    encoded = match[1].gsub(/[;\s]/,"")
    StringIO.new(Base64.strict_decode64(encoded))
  rescue ArgumentError
    nil
  end
end
