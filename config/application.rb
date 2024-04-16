require_relative "boot"

# Require Rails manually to avoid unused rails components
# active_storage/engine
# action_cable/engine
# action_mailbox/engine
# action_text/engine
# rails/test_unit/railtie
require "rails"
%w[
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
].each do |railtie|
  require railtie
rescue LoadError
end

require "rack/contrib"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Manyfold
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Load locale files in nested folders as well as locale root
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    config.i18n.fallbacks = true
    config.i18n.default_locale = :en
    config.i18n.available_locales = [
      :en,
      :de,
      :fr,
      :pl
    ]

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.middleware.use Rack::Locale

    # Treat pundit failures as standard "forbidden"
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    # Enable X-Sendfile with Thruster in all environments
    config.action_dispatch.x_sendfile_header = "X-Sendfile"

    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_SERVER", nil),
      user_name: ENV.fetch("SMTP_USERNAME", nil),
      password: ENV.fetch("SMTP_PASSWORD", nil)
    }.compact
  end
end

# Set default URL options from env vars
Rails.application.default_url_options = {
  host: ENV.fetch("PUBLIC_HOSTNAME", "localhost"),
  port: ENV.fetch("PUBLIC_PORT", nil)
}.compact
