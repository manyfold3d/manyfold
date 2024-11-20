class Settings::UsersController < ApplicationController
  def index
    @users = policy_scope(Federails::Actor).where(entity_type: "User")
    render layout: "settings"
  end

  private

  def get_user
    policy_scope(User).find_param(:id)
  end

  def user_params
    params.require(:user).permit
  end
end
