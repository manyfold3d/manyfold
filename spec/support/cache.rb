RSpec.configure do |config|
  config.after do
    Rails.cache.clear
  end
end
