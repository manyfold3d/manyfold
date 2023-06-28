FactoryBot.define do
  factory :creator do
    name { Faker::Name.name }
  end
end
