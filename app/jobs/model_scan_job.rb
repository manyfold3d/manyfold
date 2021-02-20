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
        p = model.parts.create(filename: filename.gsub(model_path + "/", ""))
        model.preview_part ||= p
      end
      model.save!
    end
    model.autogenerate_tags_from_path!
  end
end
