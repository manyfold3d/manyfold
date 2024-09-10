class CacheSweepJob < ApplicationJob
  def perform
    cache = Shrine.storages[:cache]
    cache.clear! { |path| path.mtime < 6.hours.ago }
  end
end
