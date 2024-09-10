class CacheSweepJob < ApplicationJob
  def perform
    cache = Shrine.storages[:cache]
    cache.clear! { |path| path.mtime < (Time.now - 6.hours) }
  end
end
