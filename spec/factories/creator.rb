FactoryBot.define do
  factory :creator do
    sequence(:name) { |n| "Creator #{n}" }
    sequence(:public_id) { |n| "creator_#{n}" }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    links_attributes { [{url: "http://example.com"}] }

    trait :public do
      caber_relations_attributes { [{subject: nil, permission: "view"}] }
    end
  end
end
