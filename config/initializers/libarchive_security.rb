module Archive
  EXTRACT_SECURE_WITH_OVERWRITE = [
    Archive::EXTRACT_TIME,
    Archive::EXTRACT_SECURE_NODOTDOT
  ].reduce(:|).to_i

  # Create a preset "secure extraction" flag combination for libarchive to make sure we avoid security problems
  # See https://github.com/libarchive/libarchive/blob/6ee1eebefdf41f36ef1a548c9a7000d132c453f3/libarchive/archive.h#L662
  EXTRACT_SECURE = [
    Archive::EXTRACT_SECURE_WITH_OVERWRITE,
    Archive::EXTRACT_NO_OVERWRITE,
    Archive::EXTRACT_NO_OVERWRITE_NEWER
  ].reduce(:|).to_i
end
