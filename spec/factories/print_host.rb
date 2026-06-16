FactoryBot.define do
  factory :print_host do
    name { Faker::Name.first_name }
    endpoint { Faker::Internet.url }
    protocol { "moonraker" }
  end
end
