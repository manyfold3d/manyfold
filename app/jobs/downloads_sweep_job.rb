class DownloadsSweepJob < ApplicationJob
  def perform
    return if SiteSettings.download_expiry_time_in_hours == 0 # zero expiry time means keep forever

    ModelFileUploader.storages[:downloads].clear! do |path|
      path.mtime < SiteSettings.download_expiry_time_in_hours.hours.ago
    end
  end
end
