FactoryBot.define do
  factory :part do
    filename { Faker::File.file_name(ext: "stl") }
    model { build :model }
  end
end
