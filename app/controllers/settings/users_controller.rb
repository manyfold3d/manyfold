class Settings::UsersController < ApplicationController
  before_action :get_user, except: [:index]

  def index
    @users = policy_scope(Federails::Actor).where(entity_type: "User").where.not(entity_id: nil)
    render layout: "settings"
  end

  def show
    render layout: "settings"
  end

  def edit
    render layout: "settings"
  end


  private

  def get_user
    @user = policy_scope(User).find_param(params[:id])
    authorize @user
  end

  def user_params
    params.require(:user).permit
  end
end
