class LibraryScanJob < ApplicationJob
  queue_as :default

  # Find all files in the library that we might need to look at
  def filenames_on_disk(library)
    Dir.glob(File.join(library.path, "**", ApplicationJob.file_pattern)).filter { |x| File.file?(x) }
  end

  # Get a list of all the existing filenames
  def known_filenames(library)
    library.model_files.reload.map do |x|
      File.join(library.path, x.model.path, x.filename)
    end
  end

  def filter_out_common_subfolders(folders)
    ignorable_leaf_folders = [
      "files", # Thingiverse download structure
      "images" # Thingiverse download structure
    ]
    matcher = /\/(#{ignorable_leaf_folders.join('|')})$/
    folders.map { |f| f.gsub(matcher, "") }.uniq
  end

  def perform(library)
    return if Problem.create_or_clear(library, :missing, !File.exist?(library.path))
    # Make a list of changed filenames using set XOR
    changes = (known_filenames(library).to_set ^ filenames_on_disk(library)).to_a
    # Make a list of library-relative folders with changed files
    folders_with_changes = changes.map { |f| File.dirname(f.gsub(library.path, "")) }.uniq
    folders_with_changes = filter_out_common_subfolders(folders_with_changes)
    folders_with_changes.delete("/")
    folders_with_changes.compact_blank!
    # For each folder in the library with a change, find or create a model, then scan it
    folders_with_changes.each do |path|
      new_model_properties = {
        # Initial best guess at name, this might be overwritten later by path parser
        name: File.basename(path).humanize.tr("+", " ").titleize
      }
      model = library.models.create_with(new_model_properties).find_or_create_by(path: path.trim_path_separators)
      if model.valid?
        ModelScanJob.perform_later(model)
      else
        Rails.logger.error(model.inspect)
        Rails.logger.error(model.errors.full_messages.inspect)
      end
    end
    # Run integrity check on all models
    library.models.each do |model|
      Scan::CheckModelIntegrityJob.perform_later(model)
    end
  end
end
