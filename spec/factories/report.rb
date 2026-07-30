FactoryBot.define do
  factory :report, class: "Fedipub::Moderation::Report" do
    federated_url { Faker::Internet.url }
    fedipub_actor { create(:user).fedipub_actor }
    object { association :model }
    content { Faker::Lorem.sentence }
  end
end
