FactoryBot.define do
  factory :problem do
    category { :missing }
    problematic { association :model_file }
  end
end
