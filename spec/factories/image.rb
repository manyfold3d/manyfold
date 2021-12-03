FactoryBot.define do
  factory :image do
    filename { Faker::File.file_name(ext: "jpg") }
    model { build :model }
  end
end
