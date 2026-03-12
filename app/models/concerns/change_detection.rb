module ChangeDetection
  extend ActiveSupport::Concern

  # Get a list of all the files in the library storage that could be indexed
  def indexable_files
    list_files(File.join("**", FileMatcher.file_pattern))
  end

  def indexed_files
    model_files.includes(:model).without_special.pluck("models.path", :filename).map { |it| File.join(it) }
  end
end
