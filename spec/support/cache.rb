RSpec.configure do |config|
  config.after do
    Amiko.cache.clear
  end
end
