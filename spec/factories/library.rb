FactoryBot.define do
  factory :library do
    path { Faker::File.dir }
  end
end
