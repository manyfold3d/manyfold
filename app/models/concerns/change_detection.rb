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

  def sample(num = 3)
    remaining_attempts = num * 5 # Got to have some kind of cutoff
    rng = Random.new(path.unpack1("S")) # See a random number generator with the path so that the random selections are stable for each library
    results = []
    while results.length < num && remaining_attempts > 0
      leaf = dive_for_leaf_folder(path, nil, rng)
      results << leaf if leaf
      remaining_attempts -= 1
      results = results.compact.sort.uniq
    end
    results
  end

  private

  def dive_for_leaf_folder(absolute_path, folder, rng)
    # If this is a leaf folder, we're done
    return folder if leaf_folder?(absolute_path)
    # Otherwise, choose a random folder
    folders = Dir.entries(absolute_path).select do |it|
      FileTest.directory?(File.join(absolute_path, it)) &&
        !SiteSettings.ignored_file?(File.join(absolute_path, it)) &&
        !it.starts_with?(".")
    end
    f = folders.sample(random: rng)
    if f
      next_folder = File.join([folder, f].compact)
      next_path = File.join(absolute_path, f)
      leaf = dive_for_leaf_folder(next_path, next_folder, rng)
      f.in?(FileMatcher.common_subfolders) ? folder : leaf
    end
  end

  def leaf_folder?(path)
    Dir.glob(File.join(path, FileMatcher.file_pattern)).any?
  end
end
