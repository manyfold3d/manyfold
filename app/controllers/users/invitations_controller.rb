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
      flash[:alert] = t(".altcha_failed")
      render :edit, status: :unprocessable_content
    end
  end
end
