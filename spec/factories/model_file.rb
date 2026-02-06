FactoryBot.define do
  factory :model_file do
    model
    filename { Faker::File.file_name(ext: "stl") }
    attachment { filename ? Rack::Test::UploadedFile.new(StringIO.new("solid #{filename}\n"), original_filename: filename) : nil }
  end
end
