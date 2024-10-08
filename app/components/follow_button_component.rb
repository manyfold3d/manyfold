# frozen_string_literal: true

class FollowButtonComponent < ViewComponent::Base
  def initialize(follower:, target:, name: nil)
    @target = target
    @following = follower&.following? target
    @name = name
  end

  def before_render
    @path = url_for(@target) + "/follows"
    @method = @following ? :delete : :post
    @i18n_key = @following ? ".unfollow" : ".follow"
  end

  def render?
    (SiteSettings.multiuser_enabled? || SiteSettings.federation_enabled?) && helpers.policy(Federails::Following).create?
  end

  erb_template <<-ERB
    <%= button_to translate(@i18n_key, name: @name), @path, method: @method, class: "btn btn-primary" %>
  ERB
end
