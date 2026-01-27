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
    # Code taken from doorkeeper cleanup rake task

    # Removes stale access tokens
    cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper.config.access_token_model)
    cleaner.clean_revoked

    # Removes expired (TTL passed) access tokens
    expirable_tokens = Doorkeeper.config.access_token_model.where(refresh_token: nil)
    cleaner = Doorkeeper::StaleRecordsCleaner.new(expirable_tokens)
    cleaner.clean_expired(Doorkeeper.config.access_token_expires_in)

    # Removes stale access grants
    cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper.config.access_grant_model)
    cleaner.clean_revoked

    # Removes expired (TTL passed) access grants
    cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper.config.access_grant_model)
    cleaner.clean_expired(Doorkeeper.config.authorization_code_expires_in)
  end
end
