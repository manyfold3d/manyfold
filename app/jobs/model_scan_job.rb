class ModelScanJob < ApplicationJob
  queue_as :default

  def self.file_pattern
    lower = Rails.configuration.formats[:models].map(&:downcase) + Rails.configuration.formats[:images].map(&:downcase)
    upper = Rails.configuration.formats[:models].map(&:upcase) + Rails.configuration.formats[:images].map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  def perform(model)
    # For each file in the model, create a file object
    model_path = File.join(model.library.path, model.path)
    Dir.open(model_path) do |dir|
      Dir.glob([
        File.join(dir.path, ModelScanJob.file_pattern),
        File.join(dir.path, "files", ModelScanJob.file_pattern)
      ]).each do |filename|
        model.model_files.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
      end
    end
    # Clean out missing files
    model.model_files.select { |f|
      !File.exist?(File.join(model_path, f.filename))
    }.each(&:destroy)
    # Set tags and default files
    model.model_files.reload
    model.preview_file = model.model_files.first
    model.autogenerate_tags_from_path!
  end
end
