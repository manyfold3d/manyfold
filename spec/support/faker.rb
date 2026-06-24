RSpec.configure do |config|
  config.after do
    Faker::UniqueGenerator.clear
  end
end
