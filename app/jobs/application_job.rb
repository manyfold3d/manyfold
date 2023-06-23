class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  before_perform do |job|
    SiteSettings.clear_cache
  end

  def self.case_insensitive_glob(extensions)
    [
      "*.{",
      extensions.map { |ext|
        ext.chars.map { |char|
          "[#{char.upcase}#{char.downcase}]"
        }.join
      }.join(","),
      "}"
    ].join
  end

  def self.image_pattern
    case_insensitive_glob(SupportedMimeTypes.image_extensions)
  end

  def self.file_pattern
    case_insensitive_glob(SupportedMimeTypes.image_extensions + SupportedMimeTypes.model_extensions)
  end

  def self.common_subfolders
    {
      "files" => file_pattern,
      "images" => image_pattern,
      "presupported" => file_pattern,
      "supported" => file_pattern,
      "unsupported" => file_pattern,
      "parts" => file_pattern
    }
  end
end
