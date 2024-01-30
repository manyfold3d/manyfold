FactoryBot.define do
  factory :user do
    username { Faker::Internet.username }
    admin { false }
  end
end
