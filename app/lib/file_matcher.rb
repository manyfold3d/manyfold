module FileMatcher
  def self.extension_glob(extensions)
    [
      "*.{",
      extensions.map { |ext| case_insensitive_glob_string(ext) }.join(","),
      "}"
    ].join
  end

  def self.case_insensitive_glob_string(str)
    str.chars.map { |char|
      "[#{char.upcase}#{char.downcase}]"
    }.join
  end

  def self.image_pattern
    extension_glob(SupportedMimeTypes.image_extensions)
  end

  def self.file_pattern
    extension_glob(SupportedMimeTypes.indexable_extensions)
  end

  def self.common_subfolders
    {
      "3mf" => file_pattern,
      "fdm" => file_pattern,
      "files" => file_pattern,
      "images" => image_pattern,
      "lychee" => file_pattern,
      "lys" => file_pattern,
      "model" => file_pattern,
      "obj" => file_pattern,
      "parts" => file_pattern,
      "presupported" => file_pattern,
      "resin" => file_pattern,
      "stl" => file_pattern,
      "sup" => file_pattern,
      "supported" => file_pattern,
      "unsupported" => file_pattern
    }
  end
end
