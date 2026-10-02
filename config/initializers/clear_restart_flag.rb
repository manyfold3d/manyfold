Mosscap.application.config.after_initialize do
  Mosscap.cache.delete("restart_required")
end
