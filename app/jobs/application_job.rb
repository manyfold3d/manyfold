class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status
  sidekiq_options retry: false

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  before_perform do |job|
    SiteSettings.clear_cache
    job.status.update( started_at: DateTime.now )
  end

  after_perform do |job|
    job.status.update(
      finished_at: DateTime.now,
      step: nil
    )
  end

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
    extension_glob(SupportedMimeTypes.image_extensions + SupportedMimeTypes.model_extensions)
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
