[
  "FileHandlers_handlers_for_*"
].each do
  Rails.cache.delete_matched it
end
