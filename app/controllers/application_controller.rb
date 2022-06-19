class ApplicationController < ActionController::Base
  before_action :auto_login_single_user
  before_action :authenticate_user!

  def auto_login_single_user
    # If there is a single user with no password set,
    # then log in automatically as that user.
    if User.count == 1 && User.first.encrypted_password == ""
      sign_in(:user, User.first)
    end
  end

  def authenticate_admin_user!
    authenticate_user!
    render plain: "401 Unauthorized", status: :unauthorized unless current_user.admin?
  end
end
