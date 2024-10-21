# frozen_string_literal: true

class FollowButtonComponent < ViewComponent::Base
  def initialize(follower:, target:, name: nil)
    @signed_out = follower.nil?
    @target = target
    @following = follower&.following? target
    @name = name
  end

  def before_render
    @i18n_key = @following ? ".unfollow" : ".follow"
    @icon = @following ? "person-x-fill" : "person-plus-fill"
    if @signed_out
      @path = @target.is_a?(Federails::Actor) ?
        follow_remote_actor_path(@target) :
        remote_follow_path(uri: @target.actor.federated_url, name: @target.name)
      @method = :post
    else
      @path = @target.is_a?(Federails::Actor) ?
        follow_remote_actor_path(@target) :
        url_for(@target) + "/follows"
      @method = @following ? :delete : :post
    end
  end

  def render?
    social_enabled? && (helpers.policy(Federails::Following).create? || remote_follow_allowed?)
  end

  erb_template <<-ERB
    <%= button_to safe_join([helpers.icon(@icon, ""), translate(@i18n_key, name: @name)], " "), @path, method: @method, class: "btn btn-primary" %>
  ERB

  private

  def social_enabled?
    SiteSettings.multiuser_enabled? || SiteSettings.federation_enabled?
  end

  def remote_follow_allowed?
    SiteSettings.federation_enabled? && @signed_out
  end
end
