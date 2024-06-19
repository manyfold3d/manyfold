# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header


scout_options = Rails.env.production? ? [] : [
  "https://apm.scoutapp.com", "https://scoutapm.com"
]

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.frame_ancestors :self
    policy.frame_src :none
    policy.img_src *([:self, :unsafe_inline] + scout_options)
    policy.object_src :none
    policy.script_src *([:self] + scout_options)
    policy.style_src *([:self] + scout_options)
  end

  config.content_security_policy_nonce_generator = -> request { request.session.id.to_s }

end
