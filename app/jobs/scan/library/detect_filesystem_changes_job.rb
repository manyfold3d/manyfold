class Scan::Library::DetectFilesystemChangesJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  # Find all files in the library that we might need to look at
  def filenames_on_disk(library)
    library.list_files(File.join("**", ApplicationJob.file_pattern))
  end

  # Get a list of all the existing filenames
  def known_filenames(library)
    library.model_files.without_special.reload.map(&:path_within_library)
  end

  def filter_out_common_subfolders(folders)
    matcher = /\/(#{ApplicationJob.common_subfolders.keys.join("|")})$/i
    folders.map { |f| f.gsub(matcher, "") }.uniq
  end

  def folders_with_changes(library)
    # Make a list of changed filenames using set XOR
    status[:step] = "jobs.scan.detect_filesystem_changes.building_filename_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_filename_list')
    changes = (known_filenames(library).to_set ^ filenames_on_disk(library)).to_a
    # Double-check that we only consider indexable files in the changelist
    # This is because some non-indexable files might have been added by uploading
    # (that might be a bug - or a feature)
    changes.select! { |f| SupportedMimeTypes.indexable_extensions.include? File.extname(f).tr(".", "") }
    # Discard thingiverse false-positives - sometimes they add images that have model extensions.
    patterns = SupportedMimeTypes.model_extensions.map { |it| %r{images/[^/]*\.#{it}} }
    changes = changes.reject { |f| patterns.any? { |it| f =~ it } }
    # Make a list of library-relative folders with changed files
    status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_folder_list')
    folders_with_changes = changes.map { |f| File.dirname(f) }.uniq
    folders_with_changes = filter_out_common_subfolders(folders_with_changes)
    # Ignore root folder, however specified
    folders_with_changes.delete("/")
    folders_with_changes.delete(".")
    folders_with_changes.delete("./")
    # Trim out anything left blank and we're done
    folders_with_changes.compact_blank
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
