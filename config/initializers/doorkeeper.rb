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
