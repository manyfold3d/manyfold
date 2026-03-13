class Scan::Library::DetectFilesystemChangesJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(library_id)
    # Make a list of library-relative folders with changed files
    library = Library.find(library_id)
    return if library.nil?
    return if Problem.create_or_clear(library, :missing, !library.storage_exists?)
    # Find folders with changes
    status[:step] = "jobs.scan.detect_filesystem_changes.building_folder_list" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.building_folder_list')
    changes = library.folders_with_changes
    # For each folder in the library with a change, find or create a model, then scan it
    status[:step] = "jobs.scan.detect_filesystem_changes.creating_models" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.creating_models')
    changes.each { |path| library.create_model_from_path_later(path) }
  end
end
