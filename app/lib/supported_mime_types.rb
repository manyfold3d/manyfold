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

  def self.icon(ext)
    return "badge-3d" if self.model_extensions.include?(ext)
    return "file-earmark-image" if self.image_extensions.include?(ext)
    return "file-zip" if %w(zip rar 7z gz z tar bz2 xz dmg tgz tbz2 txz).include?(ext)
    return "filetype-#{ext}" if %w(aac ai bmp cs css csv doc docx exe gif heic html java jpg js json jsx key m4p md mdx mov mp3 mp4 otf pdf php png ppt pptx psd py raw rb sass scss sh sql svg tiff tsx ttf txt wav woff xls xlsx xml yml).include?(ext)
    return "file-earmark"
  end
end
