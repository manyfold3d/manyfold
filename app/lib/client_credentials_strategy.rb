class ClientCredentialsStrategy < Devise::Strategies::Authenticatable
  def valid?
    request.format.manyfold_api_v0? || request.headers.key?("Authorization")
  end

  def authenticate!
    token = ::Doorkeeper::OAuth::Token.authenticate(request, :from_bearer_authorization)
    fail! and throw(:warden, status: :unauthorized) unless token&.accessible?

    scopes = case request.env.dig("action_dispatch.request.parameters", "action") || request.env.dig("action_dispatch.route_uri_pattern")
    when "index", "show", "raw"
      ["public", "read"]
    when "create", "update", "raw_put"
      ["write"]
    when "destroy"
      ["delete"]
    when "/upload"
      ["upload"]
    else
      [""]
    end
    fail! and throw(:warden, status: :forbidden) unless token.acceptable?(scopes)

    scopes_required_for_this_action = token.scopes & scopes

    # If an owner-specific scope is in use, set the resource owner
    if (scopes_required_for_this_action & ["read", "write", "delete", "upload"]).any?
      # If this is a client credentials flow, the resource owner should be the owner of the application
      resource_owner = token.application&.owner
      # Sign in resource owner
      if resource_owner&.active_for_authentication?
        request.session_options[:skip] = true
        success! resource_owner
      end
    end
  end
end
