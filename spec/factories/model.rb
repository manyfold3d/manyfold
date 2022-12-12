FactoryBot.define do
  factory :model do
    name { Faker::Creature::Animal.name }
    path { Faker::File.dir }
    library { build(:library) }
  end
end
