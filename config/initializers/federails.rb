# frozen_string_literal: true

Federails.configure do |conf|
  conf.app_name = "Manyfold"
  conf.app_version = Rails.application.config.app_version

  scheme = Rails.application.config.force_ssl ? "https" : "http"
  conf.site_host = "#{scheme}://#{Rails.application.default_url_options[:host]}"
  conf.site_port = Rails.application.default_url_options[:port]
  conf.force_ssl = Rails.application.config.force_ssl

  conf.enable_discovery = Rails.application.config.manyfold_features[:federation] || Rails.env.test?
  conf.open_registrations = Rails.application.config.manyfold_features[:registration]
  conf.server_routes_path = "federation"
  conf.client_routes_path = "client"

  conf.remote_follow_url_method = :new_follow_url
end
