class CacheSweepJob < ApplicationJob
  def perform
    cache = ModelFileUploader.storages[:cache]
    cache.clear! { |path| path.mtime < 6.hours.ago }
    # Don't need to clear tus separately, the storage is the same place

    # Clear up old ALTCHA records
    AltchaSolution.cleanup

    # Clean up expired doorkeeper tokens
    doorkeeper_cleanup
  end

  def doorkeeper_cleanup
    Doorkeeper.config.access_token_model.find_each { |it| it.destroy unless it.accessible? }
    Doorkeeper.config.access_grant_model.find_each { |it| it.destroy unless it.accessible? }
  end
end
