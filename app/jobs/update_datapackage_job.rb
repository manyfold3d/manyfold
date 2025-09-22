class UpdateDatapackageJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    file = model.model_files.find_or_initialize_by(filename: "datapackage.json")
    file.update!(attachment: ModelFileUploader.upload(
      StringIO.new(
        JSON.pretty_generate(DataPackage::ModelSerializer.new(model).serialize)
      ),
      :cache
    ))
  end
end
