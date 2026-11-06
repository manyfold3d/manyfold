RSpec.configure do |config|
  # Forgery protection is disabled in the test environment (config/environments/test.rb),
  # so these examples turn it back on to check that it actually protects the app.
  config.around(:each, :with_csrf_protection) do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
