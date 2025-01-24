FactoryBot.define do
  factory :model do
    sequence(:name) { |n| "Model #{n}" }
    library
    sequence(:public_id) { |n| "model_#{n}" }
    path { Faker::File.dir }
    license { "MIT" }

    trait :with_tags do
      transient do
        tags_count { 2 }
      end

      after(:create) do |model, evaluator|
        evaluator.tags_count.times do |i|
          model.tag_list.add("tag_#{i}")
        end
        model.save
      end
    end

    trait :needs_organizing do
      after(:create) do |model|
        model.update!(needs_organizing: true)
      end
    end

    trait :sensitive do
      sensitive { true }
    end

    trait :with_creator do
      creator
    end

    trait :with_collection do
      collection
    end
  end
end
