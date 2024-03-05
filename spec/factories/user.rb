FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username specifier: 3, separators: [] }
    admin { false }
    password { Faker::Internet.password }
  end
end
