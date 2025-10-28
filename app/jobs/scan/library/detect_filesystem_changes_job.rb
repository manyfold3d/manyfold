class Scan::Library::DetectFilesystemChangesJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  # Process files in batches to avoid memory exhaustion
  BATCH_SIZE = 1000

  # Find all files in the library that we might need to look at
  def filenames_on_disk(library)
    library.list_files(File.join("**", ApplicationJob.file_pattern))
  end

  # Get a list of all the existing filenames
  # Uses eager loading to avoid N+1 queries
  def known_filenames(library)
    library.model_files.without_special.includes(:model).map(&:path_within_library)
  end

  def filter_out_common_subfolders(folders)
    matcher = /\/(#{ApplicationJob.common_subfolders.keys.join("|")})$/i
    folders.map { |f| f.gsub(matcher, "") }.uniq
  end

  def folders_with_changes(library)
    status[:step] = "jobs.scan.detect_filesystem_changes.building_filename_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_filename_list')

    changed_folders = Set.new

    # Build a Set of known file paths using optimized SQL query
    known_paths = known_filenames(library).to_set

    # Patterns for thingiverse false-positives
    thingiverse_patterns = SupportedMimeTypes.model_extensions.map { |it| %r{images/[^/]*\.#{it}} }

    # Get filesystem files
    disk_files = filenames_on_disk(library)

    # Convert to array if it's not already (for batching)
    disk_files = disk_files.to_a unless disk_files.is_a?(Array)

    # Find files on disk that aren't in database (new files)
    # Process in batches to reduce peak memory usage when checking against set
    disk_files.each_slice(BATCH_SIZE) do |batch|
      batch.each do |path|
        # Skip thingiverse false-positives
        next if thingiverse_patterns.any? { |pattern| path =~ pattern }

        unless known_paths.include?(path)
          # File exists on disk but not in database - it's new
          changed_folders.add(File.dirname(path))
        end
      end
    end

    # Find files in database that aren't on disk (deleted files)
    # Process known_paths in batches to reduce peak memory usage
    disk_files_set = disk_files.to_set
    known_paths.each_slice(BATCH_SIZE) do |batch|
      batch.each do |path|
        unless disk_files_set.include?(path)
          # File exists in database but not on disk - it's deleted
          changed_folders.add(File.dirname(path))
        end
      end
    end

    status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_folder_list')

    # Convert set to array and filter
    folders = changed_folders.to_a
    folders = filter_out_common_subfolders(folders)

    # Ignore root folder, however specified
    folders.delete("/")
    folders.delete(".")
    folders.delete("./")

    # Trim out anything left blank and we're done
    folders.compact_blank
  end

  def perform(library_id)
    library = Library.find(library_id)
    return if library.nil?
    return if Problem.create_or_clear(library, :missing, !library.storage_exists?)
    # For each folder in the library with a change, find or create a model, then scan it
    status[:step] = "jobs.scan.detect_filesystem_changes.creating_models" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.creating_models')
    folders_with_changes(library).each { |path| library.create_model_from_path_later(path) }
  end
end
