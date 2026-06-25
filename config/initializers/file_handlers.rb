Rails.application.config.after_initialize do
  # Clear handler caches
  [
    "FileHandlers_handlers_for_*"
  ].each do
    Rails.cache.delete_matched it
  end
  # Register all handlers
  exceptions = [
    :ALL_HANDLERS,
    :Base,
    :Slic3rFamily
  ]
  FileHandlers::ALL_HANDLERS = FileHandlers.constants.without(exceptions).map {
    Object.const_get("FileHandlers::#{it}")
  }.compact.freeze
end
