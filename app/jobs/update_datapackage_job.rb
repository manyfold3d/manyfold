class UpdateDatapackageJob < ApplicationJob
  def perform(model_id)
    model = Model.find(model_id)
    file = model.model_files.including_special.find_or_initialize_by(filename: "datapackage.json")
    file.update!(attachment: LibraryUploader.upload(
      StringIO.new(
        JSON.pretty_generate(DataPackage::ModelSerializer.new(model).serialize)
      ),
      :cache
    ))
  end
end
