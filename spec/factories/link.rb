FactoryBot.define do
  factory :link do
    url { Faker::Internet.unique.url }
    text { Faker::Internet.username }
  end
end
