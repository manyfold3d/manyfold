# frozen_string_literal: true

Federails.configure do |conf|
  conf.app_name = "Manyfold"

  conf.app_version = Rails.application.config.app_version

  conf.site_host = Rails.application.default_url_options["host"]

  conf.site_port = Rails.application.default_url_options["port"]
  conf.force_ssl = Rails.application.config.force_ssl

  conf.enable_discovery = Flipper.enabled? :federation

  conf.app_layout = "layouts/application"

  conf.user_class = "::User"

  conf.server_routes_path = "federation"

  conf.client_routes_path = "app"

  conf.user_profile_url_method = "~"

  conf.user_name_field = "~"

  conf.user_username_field = "id"

  ## Test
  # conf.site_port = "null"

  ## Production
  # conf.force_ssl = true
  #
  # conf.site_host = 443
end
