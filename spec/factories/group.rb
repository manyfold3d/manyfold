FactoryBot.define do
  factory :group do
    name { Faker::Commerce.product_name }
    creator
  end
end
