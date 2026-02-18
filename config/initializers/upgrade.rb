Rails.application.config.after_initialize do
  # Update site settings from old values
  SiteSettings.default_viewer_role = "private" if SiteSettings.default_viewer_role == ""

  # Attempt to connect to Redis first before queueing, and fail early
  Sidekiq.redis { |conn| conn.info }
  # Queue upgrade jobs if Redis is good to go
  # and if in server mode
  if Rails.const_defined?(:Server)
    Upgrade::GenerateSlugsJob.set(queue: :high).perform_later(Model)
    Upgrade::GenerateSlugsJob.set(queue: :high).perform_later(Creator)
    Upgrade::GenerateSlugsJob.set(queue: :high).perform_later(Collection)
    Upgrade::FixStaleAttachmentDataJob.set(queue: :upgrade).perform_later
    Upgrade::FixNilFileSizeValues.set(queue: :upgrade).perform_later
    Upgrade::BackfillDataPackages.set(queue: :upgrade).perform_later
    Upgrade::DisambiguateUsernamesJob.set(queue: :upgrade).perform_later
    Upgrade::UpdateActorsJob.set(queue: :upgrade).perform_later
    Upgrade::FixParentCollections.set(queue: :upgrade).perform_later
    Upgrade::PruneOrphanedProblems.set(queue: :upgrade).perform_later
    Upgrade::BackfillImageDerivatives.perform_later if SiteSettings.generate_image_derivatives
  end
rescue RedisClient::CannotConnectError
end
