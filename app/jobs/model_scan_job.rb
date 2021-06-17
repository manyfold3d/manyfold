class ModelScanJob < ApplicationJob
  queue_as :default

  def self.model_pattern
    lower = Rails.configuration.formats[:models].map(&:downcase)
    upper = Rails.configuration.formats[:models].map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  def self.image_pattern
    lower = Rails.configuration.formats[:images].map(&:downcase)
    upper = Rails.configuration.formats[:images].map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  def perform(model)
    # For each file in the model, create a part
    model_path = File.join(model.library.path, model.path)
    Dir.open(model_path) do |dir|
      Dir.glob([
        File.join(dir.path, ModelScanJob.model_pattern),
        File.join(dir.path, "files", ModelScanJob.model_pattern)
      ]).each do |filename|
        model.parts.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
      end
      Dir.glob([
        File.join(dir.path, ModelScanJob.image_pattern),
        File.join(dir.path, "images", ModelScanJob.image_pattern)
      ]).each do |filename|
        model.images.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
      end
    end
    # Clean out missing parts
    model.parts.select { |part|
      !File.exist?(File.join(model_path, part.filename))
    }.each(&:destroy)
    # Set tags and default parts
    model.parts.reload
    model.preview_part = model.parts.first
    model.autogenerate_tags_from_path!
  end
end
