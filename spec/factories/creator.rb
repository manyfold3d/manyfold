FactoryBot.define do
  factory :creator do
    name { Faker::FunnyName.name }
  end
end
