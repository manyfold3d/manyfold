# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Configured dynamically in ApplicationController#configure_content_security_policy

Rails.application.configure do
  # Disable CSP nonce if we're pulling in Scout DevTrace
  unless Rails.env.development? && ENV.fetch("SCOUT_DEV_TRACE", false) === "true"
    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  end
end
