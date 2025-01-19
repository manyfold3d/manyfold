FactoryBot.define do
  factory :tag, class: "ActsAsTaggableOn::Tag" do
    sequence(:name) { |n| "tag_#{n}" }
  end
end
