class ModelScanJob < ApplicationJob
  queue_as :default

  def perform(model)
    # For each file in the model, create a part
    model_path = File.join(model.library.path, model.path)
    Dir.open(model_path) do |dir|
      Dir.glob(File.join(dir.path, "*.stl")).each do |filename|
        model.parts.create(filename: File.basename(filename))
      end
    end
  end
end
