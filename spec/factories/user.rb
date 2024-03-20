FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username specifier: 3, separators: [] }
    password { Faker::Internet.password }

    factory :admin do
      admin { true }
    end
  end
end
