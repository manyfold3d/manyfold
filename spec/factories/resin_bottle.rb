# frozen_string_literal: true

FactoryBot.define do
  factory :resin_bottle do
    brand { "Elegoo" }
    color { "Standard Grey" }
    capacity_ml { 1000.0 }
    remaining_ml { 750.0 }
    opened_on { Date.current - 14 }

    trait :assigned do
      print_host
    end
  end
end
