FactoryBot.define do
  factory :collection do
    name { Faker::Name.name }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    links_attributes { [{url: "http://example.com"}] }

    trait :public do
      permission_preset { :public }
    end
  end
end
