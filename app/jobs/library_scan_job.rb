class LibraryScanJob < ApplicationJob
  queue_as :default

  def perform(library)
    # For each directory in the library, create a model
    all_3d_files = Dir.glob(File.join(library.path, "**", "*.stl"))
    model_folders = all_3d_files.map { |f| File.dirname(f) }.uniq
    model_folders.each do |path|
      title = relative_path = path.gsub(library.path, "")
      if title.ends_with?("/files")
        title = title.gsub("/files", "")
      end
      title = File.basename(title)
      next if relative_path.blank? # For now, ignore files in the root
      model = library.models.find_or_create_by(name: title.humanize.titleize, path: relative_path)
      ModelScanJob.perform_later(model)
    end
  end
end
