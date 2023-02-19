module SupportedMimeTypes
  def self.image_types
    Mime::LOOKUP.filter { |k, v| v.to_s.start_with?("image/") }.values.map(&:to_sym)
  end

  def self.image_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| v.to_s.start_with?("image/") }.keys
  end

  def self.model_types
    Mime::LOOKUP.filter { |k, v| v.to_s.start_with?("model/") }.values.map(&:to_sym)
  end

  def self.model_extensions
    Mime::EXTENSION_LOOKUP.filter { |k, v| v.to_s.start_with?("model/") }.keys
  end
end
