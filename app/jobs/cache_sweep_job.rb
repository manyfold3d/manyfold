class CacheSweepJob < ApplicationJob
  def perform
    cache = LibraryUploader.storages[:cache]
    cache.clear! { |path| path.mtime < 6.hours.ago }
    # Don't need to clear tus separately, the storage is the same place
  end
end
