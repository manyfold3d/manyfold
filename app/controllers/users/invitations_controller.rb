class Users::InvitationsController < Devise::InvitationsController
  def edit
    skip_authorization
    super
  end

  def update
    skip_authorization
    super
  end
end
