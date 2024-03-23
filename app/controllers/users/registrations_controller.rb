# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :detect_if_first_use, only: [:edit, :update]
  # before_action :configure_account_update_params, only: [:update]
  skip_before_action :check_for_first_use, only: [:edit, :update]

  # GET /resource/sign_up
  def new
    authorize User
    super
  end

  # GET /resource/edit
  def edit
    authorize current_user
    if @first_use
      render "first_use"
    else
      super
    end
  end

  # POST /users
  def create
    authorize User
    super
  end

  # PUT /resource
  def update
    authorize current_user
    if @first_use
      if current_user.update(account_update_params.merge(reset_password_token: nil))
        sign_in(current_user, bypass: true)
        redirect_to root_path, notice: t("devise.registrations.update.setup_complete")
      else
        render "first_use"
      end
    else
      super
    end
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
  def cancel
    authorize :"users/registrations"
    super
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  def detect_if_first_use
    if current_user.reset_password_token == "first_use"
      @first_use = true
      devise_parameter_sanitizer.permit(:account_update, keys: [:username])
    end
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
