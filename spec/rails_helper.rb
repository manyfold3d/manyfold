# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "rake"
Rails.application.load_tasks

Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Exclude case-sensitive filesystem tests if our local filesystem isn't
  Dir.mktmpdir do |tmp|
    if Sys::Filesystem.stat(tmp).case_insensitive?
      config.filter_run_excluding case_sensitive: true
    end
  end
end

# Copy parsers into integration tests - this doesn't happen automatically for some reason
[:xrd, :jrd, :activitypub, :nodeinfo].each do |mime_type|
  ActionDispatch::IntegrationTest.register_encoder mime_type,
    response_parser: ActionDispatch::Request.parameter_parsers[mime_type]
end
