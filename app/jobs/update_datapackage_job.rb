class UpdateDatapackageJob < ApplicationJob
  def perform(model_id)
    model = Model.find(model_id)

    datapackage = model.model_files.including_special.find_or_create_by(filename: "datapackage.json")

    json_file = Rack::Test::UploadedFile.new(
      StringIO.new(JSON.pretty_generate(DataPackage::ModelSerializer.new(model).serialize)),
      "application/json",
      original_filename: "datapackage.json"
    )

    datapackage.update attachment: json_file
  end
end
