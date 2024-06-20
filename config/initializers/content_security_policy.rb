# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# I'f we're using Scout DevTrace in local development, we need to allow a load
# of inline stuff, so we need to add that and disable the nonce generation

using_scout = (ENV.fetch("SCOUT_DEV_TRACE", false) === "true")

scout_csp = using_scout ? [
  :unsafe_inline, "https://apm.scoutapp.com", "https://scoutapm.com"
] : []

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.frame_ancestors :self
    policy.frame_src :none
    policy.img_src(*([:self, :data] + scout_csp))
    policy.object_src :none
    policy.script_src(*([:self] + scout_csp))
    policy.style_src(*([:self] + scout_csp))
    policy.style_src_attr :unsafe_inline
  end

  unless using_scout
    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  end
end
