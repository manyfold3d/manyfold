class FollowsController < ApplicationController
  before_action :get_target, except: [:new, :remote, :redirect_remote]

  # Incoming remote follow
  def new
    actor = Federails::Actor.find_by_federation_url(params[:uri]) # rubocop:disable Rails/DynamicFindBy
    if actor&.entity
      redirect_to actor.entity
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # Outgoing remote follow - ask for target account
  def remote
  end

  # Outgoing remote follow - perform webfinger, then redirect
  def redirect_remote
  end

  def create
    authorize Federails::Following
    current_user.follow @target
    redirect_to @target
  end

  def destroy
    authorize Federails::Following
    current_user.unfollow @target
    redirect_to @target
  end

  private

  def get_target
    followable = params[:followable_class].constantize
    followable_param = params[:followable_class].parameterize + "_id"
    id = params[followable_param]
    @target = policy_scope(followable).find(id)
  end
end
