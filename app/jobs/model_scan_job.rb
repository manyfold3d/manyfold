class ModelScanJob < ApplicationJob
  queue_as :default

  FILE_PATTERN = "*.{stl,STL,obj,OBJ}"

  def perform(model)
    # For each file in the model, create a part
    model_path = File.join(model.library.path, model.path)
    Dir.open(model_path) do |dir|
      Dir.glob([
        File.join(dir.path, FILE_PATTERN),
        File.join(dir.path, "files", FILE_PATTERN)
      ]).each do |filename|
        model.parts.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
      end
    end
    # Set tags and default parts
    model.parts.reload
    model.preview_part = model.parts.first
    model.autogenerate_tags_from_path!
  end
end
