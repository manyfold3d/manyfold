class FollowsController < ApplicationController
  before_action :get_target

  def create
    current_user.follow @target
    redirect_to @target
  end

  def destroy
    current_user.unfollow @target
    redirect_to @target
  end

  private

  def get_target
    followable = params[:followable_class].constantize
    followable_param = params[:followable_class].parameterize + "_id"
    id = params[followable_param]
    @target = followable.find(id)
  end
end
