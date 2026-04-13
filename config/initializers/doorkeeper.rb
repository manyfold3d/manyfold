# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record
  base_controller "ActionController::Base"

  # Enabled grant flows
  grant_flows %w[client_credentials]

  # Security
  hash_token_secrets
  authorization_code_expires_in 10.minutes
  access_token_expires_in 2.hours
  use_refresh_token
  forbid_redirect_uri { |uri| %w[data vbscript javascript].include?(uri.scheme.to_s.downcase) }

  # Authentication
  resource_owner_from_credentials { nil }

  # Available scopes
  default_scopes :public
  optional_scopes :read, :write, :delete
  enforce_configured_scopes

  # Per-user applications
  enable_application_owner confirmation: true
end

# i18n-tasks-use t("activerecord.models.doorkeeper/access_token")
# i18n-tasks-use t("activerecord.models.doorkeeper/application")

# Errors
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.forbidden_uri")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.fragment_present")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.invalid_uri")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.relative_uri")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.secured_uri")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.redirect_uri.unspecified_scheme")
# i18n-tasks-use t("activerecord.errors.models.doorkeeper/application.attributes.scopes.not_match_configured")
