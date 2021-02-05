FactoryBot.define do
  factory :model do
    name { Faker::Creature::Animal.name }
    path { Faker::File.file_name(dir: Faker::File.dir, ext: "stl") }
    library { build :library }
  end
end
