FactoryBot.define do
  trait :without_validations do
    to_create { |instance| instance.save(validate: false) }
  end
end
