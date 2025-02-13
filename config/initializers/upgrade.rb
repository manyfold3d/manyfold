Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.perform_async unless ModelFile.where(size: nil).count.zero?
end
