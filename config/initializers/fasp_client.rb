FaspClient.configure do |conf|
  conf.authenticate = ->(request) do
    request.env["warden"]&.user&.is_administrator?
  end
  conf.layout = "settings"
  conf.controller_base = "::ApplicationController"
end

# i18n-tasks-use t("activerecord.models.fasp_client_backfill_request")
# i18n-tasks-use t("activerecord.models.fasp_client_event_subscription")
# i18n-tasks-use t("activerecord.models.fasp_client_provider")
