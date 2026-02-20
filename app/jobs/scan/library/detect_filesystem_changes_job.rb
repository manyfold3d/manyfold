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

  def changed_files(library)
    # Make a list of changed filenames using set XOR
    status[:step] = "jobs.scan.detect_filesystem_changes.building_filename_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_filename_list')
    changes = (known_filenames(library).to_set ^ filenames_on_disk(library)).to_a
    # Double-check that we only consider indexable files in the changelist
    changes.select! { |f| SupportedMimeTypes.indexable_extensions.include? File.extname(f).tr(".", "") }
    # Discard thingiverse false-positives - sometimes they add images that have model extensions.
    patterns = SupportedMimeTypes.model_extensions.map { |it| %r{images/[^/]*\.#{it}} }
    changes.reject { |f| patterns.any? { |it| f =~ it } }
  end

  def folders_with_changes(library)
    # Make a list of library-relative folders with changed files
    status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_folder_list')
    folders = changed_files(library).map { |f| File.dirname(f) }.uniq
    folders = filter_out_common_subfolders(folders)
    # Ignore root folder, however specified
    folders.delete("/")
    folders.delete(".")
    folders.delete("./")
    # Trim out anything left blank and we're done
    folders.compact_blank
  end

  # Group changed files by base name for flat-folder scanning.
  # Strips file extensions and known support suffixes to find the base identity.
  def group_files_by_base_name(files)
    suffix_pattern = /[_-](?:#{ModelFile::SUPPORT_KEYWORDS.join("|")})$/i
    files.group_by do |filepath|
      basename = File.basename(filepath, ".*")
      basename.sub(suffix_pattern, "")
    end
  end

  # For flat-folder scanning: find all changed files and create virtual models per file group
  def create_flat_folder_models(library)
    changes = changed_files(library)
    # Group by folder first
    files_by_folder = changes.group_by { |f| File.dirname(f) }
    files_by_folder.each do |folder, files|
      # Group files within this folder by base name
      groups = group_files_by_base_name(files)
      groups.each do |base_name, _group_files|
        # Create a virtual model path using @ prefix
        virtual_path = if folder == "." || folder == "/" || folder == "./"
          "@#{base_name}"
        else
          File.join(folder, "@#{base_name}")
        end
        library.create_model_from_path_later(virtual_path)
      end
    end
  end

  def perform(library_id)
    library = Library.find(library_id)
    return if library.nil?
    return if Problem.create_or_clear(library, :missing, !library.storage_exists?)
    # For each folder in the library with a change, find or create a model, then scan it
    status[:step] = "jobs.scan.detect_filesystem_changes.creating_models" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.creating_models')
    if library.flat_folder_scanning
      create_flat_folder_models(library)
    else
      folders_with_changes(library).each { |path| library.create_model_from_path_later(path) }
    end
  end
end
