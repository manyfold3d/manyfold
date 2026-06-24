FactoryBot.define do
  factory :group do
    name { Faker::Commerce.unique.product_name }
    creator
  end
end
