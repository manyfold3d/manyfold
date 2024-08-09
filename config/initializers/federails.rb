# frozen_string_literal: true

Federails.configure do |conf|
  conf.app_name = "Manyfold"
  conf.app_version = Rails.application.config.app_version

  conf.site_host = Rails.application.default_url_options[:host]
  conf.site_port = Rails.application.default_url_options[:port]
  conf.force_ssl = Rails.application.config.force_ssl

  conf.enable_discovery = Rails.application.config.manyfold_features[:federation] || Rails.env.test?
  conf.server_routes_path = "federation"
  conf.client_routes_path = "client"
end
