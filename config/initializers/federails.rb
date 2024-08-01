# frozen_string_literal: true

federation_enabled = begin
  Flipper.enabled?(:federation)
rescue ActiveRecord::StatementInvalid
  false
end

Federails.configure do |conf|
  conf.app_name = "Manyfold"
  conf.app_version = Rails.application.config.app_version

  conf.site_host = Rails.application.default_url_options["host"]
  conf.site_port = Rails.application.default_url_options["port"]
  conf.force_ssl = Rails.application.config.force_ssl

  conf.enable_discovery = federation_enabled
  conf.server_routes_path = "federation"
  conf.client_routes_path = "client"

  conf.user_class = "::User"
  conf.user_profile_url_method = nil
  conf.user_name_field = "name"
  conf.user_username_field = "username"
end
