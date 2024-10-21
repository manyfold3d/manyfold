class FollowsController < ApplicationController
  before_action :get_target, except: [:index, :new, :remote_follow, :perform_remote_follow, :follow_remote_actor]
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: [:new, :remote_follow, :perform_remote_follow]

  def index
    authorize Federails::Following
    render :new
  end

  # Incoming remote follow
  def new
    @query = params[:uri].gsub(/\A@/, "")
    @actor = if @query.starts_with?(%r{https?://})
      Federails::Actor.find_by_federation_url @query # rubocop:disable RSpec/DynamicFindBy
    else
      Federails::Actor.find_by_account @query # rubocop:disable RSpec/DynamicFindBy
    end
    @actor = Federails::Actor.find_or_create_by_federation_url @actor.federated_url
    # If local, go to the real thing
    # This will happen if anyone comes here from a remote follow
    redirect_to url_for(@actor.entity) if @actor&.local?
    # If not local, we show a follow button and some details of the account
  rescue ActiveRecord::RecordNotFound
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

  def follow_remote_actor
    authorize Federails::Following, :create?
    @actor = Federails::Actor.find_param(params[:id])
    current_user.follow(@actor)
    redirect_to root_url, notice: t(".followed", actor: @actor.at_address)
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
    @target = policy_scope(followable).find_param(id)
  end
end
