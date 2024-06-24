FactoryBot.define do
  factory :model do
    library
    name { Faker::Creature::Animal.name }
    path { Faker::File.dir }
    license { "MIT" }
  end
end
