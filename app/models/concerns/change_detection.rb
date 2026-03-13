module ChangeDetection
  extend ActiveSupport::Concern

  # Get a list of all the files in the library storage that could be indexed
  def indexable_files
    list_files(File.join("**", FileMatcher.file_pattern))
  end

  def indexed_files
    model_files.includes(:model).without_special.pluck("models.path", :filename).map { |it| File.join(it) }
  end

  def folders_with_changes
    # Make a list of changed filenames using set XOR
    changes = (indexed_files.to_set ^ indexable_files).to_a
    # Double-check that we only consider indexable files in the changelist
    # This is because some non-indexable files might have been added by uploading
    # (that might be a bug - or a feature)
    changes.select! { |f| SupportedMimeTypes.indexable_extensions.include? File.extname(f).tr(".", "") }
    # Discard thingiverse false-positives - sometimes they add images that have model extensions.
    patterns = SupportedMimeTypes.model_extensions.map { |it| %r{images/[^/]*\.#{it}} }
    changes = changes.reject { |f| patterns.any? { |it| f =~ it } }
    # Make a list of library-relative folders with changed files
    folders_with_changes = changes.map { |f| File.dirname(f) }.uniq
    folders_with_changes = filter_out_common_subfolders(folders_with_changes)
    # Ignore root folder, however specified
    folders_with_changes.delete("/")
    folders_with_changes.delete(".")
    folders_with_changes.delete("./")
    # Trim out anything left blank and we're done
    folders_with_changes.compact_blank
  end

  def filter_out_common_subfolders(folders)
    matcher = /\/(#{FileMatcher.common_subfolders.keys.join("|")})$/i
    folders.map { |f| f.gsub(matcher, "") }.uniq
  end
end
