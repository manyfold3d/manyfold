class LibraryScanJob < ApplicationJob
  queue_as :default

  def self.file_pattern
    lower = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:downcase)
    upper = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  def perform(library)
    # For each directory in the library, create a model
    all_3d_files = Dir.glob(File.join(library.path, "**", LibraryScanJob.file_pattern))
    model_folders = all_3d_files.map { |f| File.dirname(f) }.uniq
    model_folders = model_folders.map { |f| f.gsub(/\/files$/, "").gsub(/\/images$/, "") }.uniq # Ignore thingiverse subfolders
    model_folders.each do |path|
      relative_path = path.gsub(library.path, "")
      next if relative_path.blank? # For now, ignore files in the root
      model = library.models.find_or_create_by(name: File.basename(relative_path).humanize.tr("+", " ").titleize, path: relative_path)
      if model.valid?
        ModelScanJob.perform_later(model)
      else
        Rails.logger.error(model.inspect)
        Rails.logger.error(model.errors.full_messages.inspect)
      end
    end
    # Remove models with missing path
    library.models.each do |m|
      m.destroy unless File.exist?(File.join(library.path, m.path))
    end
  end
end
