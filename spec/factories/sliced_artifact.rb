# frozen_string_literal: true

FactoryBot.define do
  factory :sliced_artifact do
    model
    print_host
    format { "ctb" }
    estimated_layers { 1400 }
    estimated_duration_seconds { 4200 }
    estimated_resin_ml { 52.0 }
  end
end
