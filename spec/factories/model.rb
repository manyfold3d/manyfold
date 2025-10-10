FactoryBot.define do
  factory :model do
    sequence(:name) { |n| "Model #{n}" }
    library
    sequence(:public_id) { |n| "model_#{n}" }
    path { Faker::File.dir } # rubocop:disable RSpec/MissingExampleGroupArgument, RSpec/EmptyExampleGroup

    license { "MIT" }
    caption { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    links_attributes { [{url: "http://example.com"}] }

    tag_list { "!new" }

    trait :with_tags do
      transient do
        tags_count { 2 }
      end

      after(:create) do |model, evaluator|
        evaluator.tags_count.times do |i|
          model.tag_list.add("Tag ##{i}")
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

    trait :public do
      permission_preset { :public }
      creator factory: [:creator, :public]
    end

    trait :remote do
      after(:create) do |model|
        model.federails_actor.update_attribute(:local, false) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
