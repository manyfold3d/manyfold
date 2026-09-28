RSpec.configure do |config|
  config.after do
    Mosscap.cache.clear
  end
end
