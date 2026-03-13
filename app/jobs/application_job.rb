class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  sidekiq_options retry: 10

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound unless Rails.env.test?
  after_discard do |_job, exception|
    Rails.logger.debug exception.to_s
  end

  before_perform do |job|
    begin
      SiteSettings.clear_cache
      Library.register_all_storage
    rescue
      nil
    end
    job.status.update(started_at: DateTime.now)
  end

  after_perform do |job|
    job.status.update(
      finished_at: DateTime.now,
      step: nil
    )
  end
end
