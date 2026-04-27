FactoryBot.define do
  factory :collection do
    name { Faker::Name.name }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    links_attributes { [{url: "http://example.com"}] }

    trait :public do
      permission_preset { :public }
    end

    trait :with_cover do
      cover { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "cover.png") }
    end
  end
end
