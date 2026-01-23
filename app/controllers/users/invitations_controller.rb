class Users::InvitationsController < Devise::InvitationsController
  def edit
    skip_authorization
    super
  end

  def update
    skip_authorization
    if AltchaSolution.verify_and_save(params.permit(:altcha)[:altcha])
      super
    else
      params[:invitation_token] = params[:user][:invitation_token]
      set_minimum_password_length
      resource_from_invitation_token
      resource.invitation_token = params[:invitation_token]
      flash[:alert] = t("users.registrations.create.altcha_failed")
      render :edit, status: :unprocessable_content
    end
  end

  private

  def update_resource_params
    params.expect(user: [:username, :password, :password_confirmation, :invitation_token])
  end
end
