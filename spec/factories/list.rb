FactoryBot.define do
  factory :list do
    name { Faker::Name.unique.name }
  end
end
