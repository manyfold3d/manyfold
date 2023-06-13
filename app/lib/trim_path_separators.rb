module TrimPathSeparators
  TRIM_PATH_SEPARATOR_REGEXP = /(^#{File::SEPARATOR})|(#{File::SEPARATOR}$)/

  def trim_path_separators
    gsub(TRIM_PATH_SEPARATOR_REGEXP, "")
  end
end
