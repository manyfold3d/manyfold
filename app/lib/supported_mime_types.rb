module SupportedMimeTypes
  def self.image_types
    Mime::LOOKUP.filter { |k, v| is_image_mime_type?(v) }.values
  end

  def self.image_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| is_image_mime_type?(v) }.keys
  end

  def self.archive_types
    Mime::LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.values
  end

  def self.archive_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.keys
  end

  def self.model_types
    Mime::LOOKUP.filter { |k, v| is_model_mime_type?(v) }.values
  end

  def self.model_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| is_model_mime_type?(v) }.keys
  end

  def self.can_export?(type)
    [:threemf].include? type
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

    def is_archive_mime_type?(type)
      [
        "application/zip",
        "application/gzip",
        "application/vnd.rar",
        "application/x-7z-compressed",
        "application/x-bzip2"
      ].include?(type.to_s)
    end
  end
end
