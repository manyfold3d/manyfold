FaspClient.configure do |conf|
  conf.authenticate = ->(request) do
    request.env["warden"]&.user&.is_administrator?
  end
  conf.layout = "settings"
  conf.controller_base = "::ApplicationController"
end

# i18n-tasks-use t("activerecord.models.fasp_client_backfill_request")
# i18n-tasks-use t("activerecord.attributes.fasp_client_backfill_request.created_at")
# i18n-tasks-use t("activerecord.attributes.fasp_client_backfill_request.category")
# i18n-tasks-use t("activerecord.attributes.fasp_client_backfill_request.max_count")

# i18n-tasks-use t("activerecord.models.fasp_client_event_subscription")
# i18n-tasks-use t("activerecord.attributes.fasp_client_event_subscription.created_at")
# i18n-tasks-use t("activerecord.attributes.fasp_client_event_subscription.category")
# i18n-tasks-use t("activerecord.attributes.fasp_client_event_subscription.subscription_type")

# i18n-tasks-use t("activerecord.models.fasp_client_provider")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.base_url")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.created_at")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.status")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.privacy_policy")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.sign_in_url")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.contact_email")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.fediverse_account")
# i18n-tasks-use t("activerecord.attributes.fasp_client_provider.fingerprint")
