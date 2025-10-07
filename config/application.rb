require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

require "rack/contrib"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Manyfold
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << config.root.join("app/uploaders")

    config.autoload_once_paths << "#{root}/app/lib"

    # Load locale files in nested folders as well as locale root
    config.i18n.load_path += Rails.root.glob("config/locales/**/*.{rb,yml}")
    config.i18n.fallbacks = true
    config.i18n.default_locale = :en
    config.i18n.available_locales = YAML.load_file(Rails.root.join("config/locales.yml"))["ready"]

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.middleware.use Rack::Locale

    # Treat pundit failures as standard "forbidden"
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_SERVER", nil),
      port: ENV.fetch("SMTP_PORT", nil),
      domain: ENV.fetch("SMTP_DOMAIN", nil),
      user_name: ENV.fetch("SMTP_USERNAME", nil),
      password: ENV.fetch("SMTP_PASSWORD", nil),
      authentication: ENV.fetch("SMTP_AUTHENTICATION", nil)&.to_sym,
      openssl_verify_mode: ENV.fetch("SMTP_OPENSSL_VERIFY_MODE", nil),
      open_timeout: ENV.fetch("SMTP_OPEN_TIMEOUT", nil)&.to_i,
      read_timeout: ENV.fetch("SMTP_READ_TIMEOUT", nil)&.to_i
    }.compact

    # Load some feature settings from ENV
    # Some are automatically enabled in test mode because they impact initialization
    config.manyfold_features = {
      multiuser: (ENV.fetch("MULTIUSER", nil) == "enabled"),
      federation: (ENV.fetch("FEDERATION", nil) == "enabled"),
      demo_mode: (ENV.fetch("DEMO_MODE", nil) == "enabled"),
      oidc: ENV.key?("OIDC_CLIENT_ID") && ENV.key?("OIDC_CLIENT_SECRET") && ENV.key?("OIDC_ISSUER")
    }
  end
end

# Set default URL options from env vars
# This is done *very* early, so that it cascades to all components
require "./app/lib/public_url"
Rails.application.default_url_options = {
  host: PublicUrl.hostname,
  port: PublicUrl.nonstandard_port
}.compact
