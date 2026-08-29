# frozen_string_literal: true

FactoryBot.define do
  factory :print_curation_note do
    model
    body { Faker::Lorem.sentence }
  end
end
