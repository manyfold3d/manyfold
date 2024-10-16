class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_after_action :verify_authorized

  def openid_connect
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      @user.add_role :administrator if User.with_role(:administrator).empty? # Create admin if there isn't one
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "OIDC") if is_navigational_format?
    else
      redirect_to new_user_session_url
      set_flash_message(:alert, :failure, kind: "OIDC", reason: @user.errors.full_messages.join("; ")) if is_navigational_format?
    end
  end
end
