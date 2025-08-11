# frozen_string_literal: true

require "fediverse/inbox"

Federails.configure do |conf|
  conf.app_name = "manyfold"
  conf.app_version = Rails.application.config.app_version

  scheme = Rails.application.config.force_ssl ? "https" : "http"
  conf.site_host = "#{scheme}://#{Rails.application.default_url_options[:host]}"
  conf.site_port = Rails.application.default_url_options[:port]
  conf.force_ssl = Rails.application.config.force_ssl

  conf.enable_discovery = Rails.application.config.manyfold_features[:federation] || Rails.env.test?
  conf.open_registrations = -> { SiteSettings.registration_enabled? }
  conf.server_routes_path = "federation"
  conf.client_routes_path = "client"

  conf.remote_follow_url_method = :new_follow_url

  conf.nodeinfo_metadata = -> do
    {"faspBaseUrl" => Rails.application.routes.url_helpers.fasp_client_url}
  end
end

Federails::Moderation.configure do |conf|
  conf.after_report_created = ->(report) { ReportHandler.call(report) }
end

Rails.application.config.after_initialize do
  Fediverse::Inbox.register_handler("Create", "*", ActivityPub::ActorActivityHandler, :handle_create_activity)
  Fediverse::Inbox.register_handler("Update", "*", ActivityPub::ActorActivityHandler, :handle_update_activity)
end
