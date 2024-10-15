# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :random_delay, only: [:create]
  before_action :auto_login_single_user
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    authorize :"users/sessions"
    super
  end

  # POST /resource/sign_in
  def create
    authorize :"users/sessions"
    super
  end

  # DELETE /resource/sign_out
  def destroy
    authorize :"users/sessions"
    super
    reset_session # Completely reset the session
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  def auto_login_single_user
    return if ENV.fetch("FORCE_OIDC", nil) == "enabled"
    # Autocreate an admin user if there isn't one
    create_admin_user if User.with_role(:administrator).empty?
    # If in single user mode, or on first run,
    # automatically log in with an admin account
    if !SiteSettings.multiuser_enabled? || User.with_role(:administrator).first.reset_password_token == "first_use"
      sign_in(:user, User.with_role(:administrator).first)
      flash.discard
      redirect_back_or_to root_path, alert: nil
    end
  end

  def create_admin_user
    password = (SecureRandom.base64(32) + "!0aB").chars.shuffle.join
    u = User.create!(
      username: SecureRandom.hex(4),
      email: "root@localhost",
      password:,
      password_confirmation: password,
      reset_password_token: "first_use"
    )
    u.add_role :administrator
    u
  end
end
