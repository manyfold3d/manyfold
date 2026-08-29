# frozen_string_literal: true

FactoryBot.define do
  factory :print_job do
    print_host
    state { :queued }
    resin_profile { "Standard Grey 0.05mm" }
    layer_count { 1200 }
    estimated_duration_seconds { 3600 }
    estimated_resin_ml { 45.5 }

    trait :printing do
      state { :printing }
      started_at { Time.current }
      current_layer { 100 }
    end

    trait :waiting_plate do
      state { :waiting_plate }
    end

    trait :succeeded do
      state { :succeeded }
      outcome { "succeeded" }
      started_at { 2.hours.ago }
      finished_at { 1.hour.ago }
      actual_duration_seconds { 3500 }
      actual_resin_ml { 44.0 }
      plate_cleared_at { nil }
    end

    trait :failed do
      state { :failed }
      outcome { "failed" }
      started_at { 1.hour.ago }
      finished_at { 30.minutes.ago }
      actual_duration_seconds { 900 }
      failure_note { "Layer adhesion failure at layer 240" }
    end

    trait :with_model do
      model
      model_file
    end
  end
end
