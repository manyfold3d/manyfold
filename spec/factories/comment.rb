FactoryBot.define do
  factory :comment do
    text { Faker::Lorem.paragraph }
  end
end
