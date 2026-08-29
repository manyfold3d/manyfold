# frozen_string_literal: true

FactoryBot.define do
  factory :print_host do
    name { Faker::Appliance.equipment }
    endpoint { "http://10.0.0.199:3030" }
    protocol { "sdcp" }
    mainboard_id { "d307202d8c1e0100" }
  end
end
