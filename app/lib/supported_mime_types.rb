module SupportedMimeTypes
  def self.image_types
    Mime::LOOKUP.filter { |k, v| is_image_mime_type?(v) }.values.map(&:to_s)
  end

  def self.image_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| is_image_mime_type?(v) }.keys
  end

  def self.model_types
    Mime::LOOKUP.filter { |k, v| is_model_mime_type?(v) }.values.map(&:to_s)
  end

  def self.model_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| is_model_mime_type?(v) }.keys
  end

  class << self
    private

    def is_image_mime_type?(type)
      type.to_s.start_with?("image/")
    end

    def is_model_mime_type?(type)
      extras = [
        "text/x-gcode",
        "application/x-openscad"
      ]
      type.to_s.start_with?("model/") || extras.include?(type.to_s)
    end
  end
end
