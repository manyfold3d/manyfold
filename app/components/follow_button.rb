# frozen_string_literal: true

class Components::FollowButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(follower:, target:, name: nil)
    @signed_out = follower.nil?
    @target = target
    @following = follower&.following? target
    @name = name
  end

  def view_template
    return unless render?
    button_to(
      @path,
      method: @method,
      class: "btn #{(@following == :pending) ? "btn-outline-primary " : "btn-primary"}"
    ) do
      span { helpers.icon(@icon, "") }
      whitespace
      span { translate(@i18n_key, name: @name) }
    end
  end

  private

  def before_template
    case @following
    when :pending
      @i18n_key = ".pending" # i18n-tasks-use t('components.follow_button.pending')
      @icon = "hourglass-split"
    when :accepted
      @i18n_key = ".unfollow" # i18n-tasks-use t('components.follow_button.unfollow')
      @icon = "person-x-fill"
    else
      @i18n_key = ".follow" # i18n-tasks-use t('components.follow_button.follow')
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
    super
  end

  def render?
    SiteSettings.social_enabled? && (helpers.policy(Federails::Following).create? || remote_follow_allowed?)
  end

  def remote_follow_allowed?
    SiteSettings.federation_enabled? && @signed_out
  end
end
