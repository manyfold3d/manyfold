FactoryBot.define do
  factory :problem do
    category { :missing }
    problematic { association :model_file }

    factory :problem_on_model do
      problematic { association :model }
    end
  end
end
