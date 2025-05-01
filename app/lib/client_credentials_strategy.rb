class ClientCredentialsStrategy < Devise::Strategies::Authenticatable
  def valid?
    request.format.manyfold_api_v0? && request.headers.key?("Authorization")
  end

  def authenticate!
    token = ::Doorkeeper::OAuth::Token.authenticate(request, :from_bearer_authorization)
    fail! and throw(:warden, status: :unauthorized) unless token&.accessible?

    scopes = case request.env.dig("action_dispatch.request.parameters", "action") || request.env.dig("action_dispatch.route_uri_pattern")
    when "index", "show"
      ["public", "read"]
    when "create", "update"
      ["write"]
    when "destroy"
      ["delete"]
    when "/upload"
      ["upload"]
    end
    fail! and throw(:warden, status: :forbidden) unless token.acceptable?(scopes)

    # If scope is :public, we need no resource owner
    resource_owner = if token.scopes == ["public"]
      nil
    else
      # If this is a client credentials flow, the resource owner should be the owner of the application
      token.application&.owner
    end
    # Sign in resource owner
    if resource_owner&.active_for_authentication?
      request.session_options[:skip] = true
      success! resource_owner
    end
  end
end
