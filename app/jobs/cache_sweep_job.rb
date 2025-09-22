class CacheSweepJob < ApplicationJob
  def perform
    cache = ModelFileUploader.storages[:cache]
    cache.clear! { |path| path.mtime < 6.hours.ago }
    # Don't need to clear tus separately, the storage is the same place

    # Clear up old ALTCHA records
    AltchaSolution.cleanup
  end
end
