# frozen_string_literal: true

FactoryBot.define do
  factory :print_vat do
    print_host
    sequence(:identity) { |n| "VAT-#{n}" }
    fep_cycles { 50 }
    status { :ready }

    trait :with_resin do
      resin_bottle
    end
  end
end
