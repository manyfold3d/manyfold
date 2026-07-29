FactoryBot.define do
  factory :report, class: "Federails::Moderation::Report" do
    federated_url { Faker::Internet.url }
    federails_actor { create(:user).fedipub_actor }
    object { association :model }
    content { Faker::Lorem.sentence }
  end
end
