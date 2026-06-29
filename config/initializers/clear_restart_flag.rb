Rails.application.config.after_initialize do
  Rails.cache.delete("restart_required")
end
