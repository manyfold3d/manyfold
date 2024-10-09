FactoryBot.define do
  factory :comment do
    comment { Faker::Lorem.paragraph }
  end
end
