# frozen_string_literal: true

class FollowButtonComponent < ViewComponent::Base
  def initialize(follower:, target:, name: nil)
    @signed_out = follower.nil?
    @target = target
    @following = follower&.following? target
    @name = name
  end

  def before_render
    case @following
    when :pending
      @i18n_key = ".pending"
      @icon = "hourglass-split"
    when :accepted
      @i18n_key = ".unfollow"
      @icon = "person-x-fill"
    else
      @i18n_key = ".follow"
      @icon = "person-plus-fill"
    end
    if @signed_out
      @path = @target.is_a?(Federails::Actor) ?
        follow_remote_actor_path(@target) :
        remote_follow_path(uri: @target.federails_actor.federated_url, name: @target.name)
      @method = :post
    else
      @path = @target.is_a?(Federails::Actor) ?
        unfollow_remote_actor_path(@target) :
        url_for(@target) + "/follows"
      @method = @following ? :delete : :post
    end
  end

  def render?
    SiteSettings.social_enabled? && (helpers.policy(Federails::Following).create? || remote_follow_allowed?)
  end

  def call
    button_to(
      safe_join([
        helpers.icon(@icon, ""),
        translate(@i18n_key, name: @name)
      ], " "),
      @path,
      method: @method,
      class: "btn #{(@following == :pending) ? "btn-outline-primary " : "btn-primary"}"
    )
  end

  private

  def remote_follow_allowed?
    SiteSettings.federation_enabled? && @signed_out
  end
end
