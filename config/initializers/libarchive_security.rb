module Archive
  # Create a preset "secure extraction" flag combination for libarchive to make sure we avoid security problems
  # See https://github.com/libarchive/libarchive/blob/6ee1eebefdf41f36ef1a548c9a7000d132c453f3/libarchive/archive.h#L662
  EXTRACT_SECURE = [
    Archive::EXTRACT_NO_OVERWRITE,
    Archive::EXTRACT_NO_OVERWRITE_NEWER,
    Archive::EXTRACT_SECURE_SYMLINKS,
    Archive::EXTRACT_SECURE_NODOTDOT,
    Archive::EXTRACT_SECURE_NOABSOLUTEPATHS
  ].reduce(:|).to_i
end
