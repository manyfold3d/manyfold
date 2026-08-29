# frozen_string_literal: true

FactoryBot.define do
  factory :print_host do
    name { Faker::Appliance.equipment }
    endpoint { "http://10.0.0.199:3030" }
    protocol { "sdcp" }
    mainboard_id { "d307202d8c1e0100" }

    trait :with_capabilities do
      brand { "UniFormation" }
      machine_model { "GK3 Pro" }
      firmware { "1.2.3" }
      mac_address { "AA:BB:CC:DD:EE:FF" }
      resolution_w { 7680 }
      resolution_h { 4320 }
      build_x_mm { 228.0 }
      build_y_mm { 128.0 }
      build_z_mm { 260.0 }
      native_formats { %w[ctb jxs] }
      fep_cycles { 120 }
      lcd_hours { 48.5 }
      storage_bytes_used { 1_073_741_824 }
      storage_bytes_total { 8_589_934_592 }
    end
  end
end
