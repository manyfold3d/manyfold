FactoryBot.define do
  factory :model_file do
    model
    filename { Faker::File.file_name(ext: "stl") }
    attachment { filename ? mock_upload(content: "solid #{filename}\n", filename: filename) : nil }
  end
end
