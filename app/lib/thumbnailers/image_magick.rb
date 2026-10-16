require "image_processing/mini_magick"

class Thumbnailers::ImageMagick
  def initialize(file:, record:)
    @file = file
    @record = record
  end

  def call
    magick = ImageProcessing::MiniMagick.source(@file)
    {
      preview: magick.resize_to_limit!(320, 320),
      carousel: magick.resize_to_limit!(1024, 768)
    }
  end
end
