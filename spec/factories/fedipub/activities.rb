FactoryBot.define do
  factory :activity, class: "Fedipub::Activity" do
    actor factory: [:actor, :local]
    entity factory: [:actor, :distant]
    action { "X" }

    trait :create do
      action { "Create" }
    end
  end
end
