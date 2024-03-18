# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :auto_login_single_user

  def auto_login_single_user
    unless Flipper.enabled? :multiuser
      sign_in(:user, User.first)
      redirect_back_or_to root_url
    end
  end

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
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
