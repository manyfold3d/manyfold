Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.perform_later
end
