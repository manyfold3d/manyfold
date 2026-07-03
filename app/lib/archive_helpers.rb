module ArchiveHelpers
  def count_common_path_components(archive)
    # Generate full list of directories in the archive
    paths = []
    files_in_root = false
    Archive::Reader.open_filename(archive.path) do |reader|
      reader.each_entry do |entry|
        paths << entry.pathname if entry.directory?
        files_in_root = true if entry.file? && entry.pathname.exclude?(File::SEPARATOR)
      end
    end
    return 0 if files_in_root
    paths = paths.map { |path| path.split(File::SEPARATOR) }
    # Count the common elements in the paths
    count_common_elements(paths)
  end

  def count_common_elements(arrays)
    return 0 if arrays.empty?
    first = arrays.shift
    zip = first.zip(*arrays)
    zip.count { it.uniq.count == 1 }
  end
end
