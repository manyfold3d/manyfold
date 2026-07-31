Amiko.application.config.after_initialize do
  Amiko.cache.delete("restart_required")
end
