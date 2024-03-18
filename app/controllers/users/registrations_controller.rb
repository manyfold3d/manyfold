# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :verify_multiuser_enabled, only: [:new, :create, :delete]
  before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    authorize User
    super
  end

  # POST /users
  def create
    authorize User
    super
  end

  # GET /resource/edit
  def edit
    authorize current_user
    super
  end

  # PUT /resource
  def update
    authorize current_user
    super
  end

  # DELETE /resource
  def destroy
    authorize current_user
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def verify_multiuser_enabled
    redirect_to '/' unless Flipper.enabled? :multiuser
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
