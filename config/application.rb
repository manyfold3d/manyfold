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
    config.eager_load_paths << config.root.join("app/uploaders")

    # Load locale files in nested folders as well as locale root
    config.i18n.load_path += Rails.root.glob("config/locales/**/*.{rb,yml}")
    config.i18n.fallbacks = true
    config.i18n.default_locale = :en
    config.i18n.available_locales = [
      :en,
      :de,
      :es,
      :fr,
      :pl
    ]

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.middleware.use Rack::Locale

    # Treat pundit failures as standard "forbidden"
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_SERVER", nil),
      user_name: ENV.fetch("SMTP_USERNAME", nil),
      password: ENV.fetch("SMTP_PASSWORD", nil)
    }.compact

    # Load some feature settings from ENV
    # Some are automatically enabled in test mode because they impact initialization
    config.manyfold_features = {
      multiuser: (ENV.fetch("MULTIUSER", nil) == "enabled"),
      registration: (ENV.fetch("REGISTRATION", nil) == "enabled"),
      federation: (ENV.fetch("FEDERATION", nil) == "enabled"),
      demo_mode: (ENV.fetch("DEMO_MODE", nil) == "enabled"),
      oidc: ENV.key?("OIDC_CLIENT_ID") && ENV.key?("OIDC_CLIENT_SECRET") && ENV.key?("OIDC_ISSUER")
    }
  end
end

# Set default URL options from env vars
port = ENV.fetch("PUBLIC_PORT", ENV.fetch("RAILS_PORT", "3214"))
Rails.application.default_url_options = {
  host: ENV.fetch("PUBLIC_HOSTNAME", "localhost"),
  port: ["80", "443"].include?(port) ? nil : port
}.compact
