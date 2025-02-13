Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.perform_later if ModelFile.where(size: nil).count > 0
end
