class FollowsController < ApplicationController
  before_action :get_target, except: [:new, :remote_follow, :perform_remote_follow]
  skip_after_action :verify_authorized, only: [:remote_follow, :perform_remote_follow]

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
  def remote_follow
    @name = params[:name]
    @uri = params[:uri]
  end

  # Outgoing remote follow - perform webfinger, then redirect
  def perform_remote_follow
    parts = Fediverse::Webfinger.split_account(params[:remote_account])
    target = Fediverse::Webfinger.remote_follow_url(parts[:username], parts[:domain], actor_url: params[:uri])
    redirect_to target, allow_other_host: true
  rescue ActiveRecord::RecordNotFound, NoMethodError
    @name = params[:name]
    @uri = params[:uri]
    @remote_account = params[:remote_account]
    render :remote_follow
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
