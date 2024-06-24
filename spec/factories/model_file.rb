FactoryBot.define do
  factory :model_file do
    model
    filename { Faker::File.file_name(ext: "stl") }
    attachment { Rack::Test::UploadedFile.new StringIO.new, original_filename: filename }
  end
end
