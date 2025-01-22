FactoryBot.define do
  factory :creator do
    sequence(:name) { |n| "Creator #{n}" }
    sequence(:public_id) { |n| "creator_#{n}" }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
  end
end
