FactoryBot.define do
  factory :creator do
    sequence(:name) { |n| "Creator #{n}" }
    sequence(:public_id) { |n| "creator_#{n}" }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    links_attributes { [{url: "http://example.com"}] }

    trait :public do
      permission_preset { :public }
    end

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "avatar.png") }
    end

    trait :with_banner do
      banner { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "banner.png") }
    end
  end
end
