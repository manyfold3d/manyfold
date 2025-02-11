Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.perform_now
end