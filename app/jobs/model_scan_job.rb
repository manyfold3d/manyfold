class ModelScanJob < ApplicationJob
  queue_as :default

  def self.file_pattern
    lower = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:downcase)
    upper = Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }.map(&:upcase)
    "*.{#{lower.zip(upper).flatten.join(",")}}"
  end

  def model_file_paths(library)
    library.model_files.reload.map do |x|
      File.join(library.path, x.model.path, x.filename)
    end
  end

  def perform(model)
    # For each file in the model, create a file object
    model_path = File.join(model.library.path, model.path)
    all_file_paths = model_file_paths(model.library)
    Dir.open(model_path) do |dir|
      Dir.glob([
        File.join(dir.path, ModelScanJob.file_pattern),
        File.join(dir.path, "files", ModelScanJob.file_pattern)
      ]).each do |filename|
        unless all_file_paths.include?(filename)
          # Create the file
          file = model.model_files.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
          # Try to guess if the file is presupported
          if !(
            File.join(model_path, filename).split(/[[:punct:]]|[[:space:]]/).map(&:downcase) &
            ["presupported", "supported", "sup", "wsupports", "withsupports"]
          ).empty?
            file.update!(presupported: true)
          end
        end
      end
    end
    # Clean out missing files
    model.model_files.select { |f|
      !File.exist?(File.join(model_path, f.filename))
    }.each(&:destroy)
    # If this model has no files, self destruct
    model.destroy if model.model_files.reload.count == 0
    # Set tags and default files
    model.model_files.reload
    model.preview_file = model.model_files.first unless model.preview_file
    model.autogenerate_tags_from_path! if model.tags.empty?
  end
end
