class LibraryScanJob < ApplicationJob
  queue_as :default

  def self.file_pattern
    lower = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:downcase)
    upper = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  # Find all files in the library that we might need to look at
  def filenames_on_disk(library)
    Dir.glob(File.join(library.path, "**", LibraryScanJob.file_pattern))
  end

  # Get a list of all the existing filenames
  def known_filenames(library)
    library.model_files.reload.map do |x|
      File.join(library.path, x.model.path, x.filename)
    end
  end

  def clean_up_missing_models(library)
    library.models.each do |m|
      m.destroy if m.missing?
    end
    nil
  end

  def clean_up_missing_model_files(library)
    library.model_files.each do |f|
      f.destroy if f.missing?
    end
    nil
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
    # Remove models with missing path
    clean_up_missing_models(library)
    clean_up_missing_model_files(library)
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
        name: File.basename(path).humanize.tr("+", " ").titleize
      }
      model = library.models.create_with(new_model_properties).find_or_create_by(path: path)
      if model.valid?
        ModelScanJob.perform_later(model)
      else
        Rails.logger.error(model.inspect)
        Rails.logger.error(model.errors.full_messages.inspect)
      end
    end
  end
end
