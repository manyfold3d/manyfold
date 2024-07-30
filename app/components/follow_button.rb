# frozen_string_literal: true

class FollowButton < ViewComponent::Base
  def initialize(follower:, target:)
    @target = target
    @following = follower.following? target
  end

  def before_render
    @path = url_for(@target) + "/follows"
    @method = @following ? :delete : :post
    @i18n_key = @following ? ".unfollow" : ".follow"
  end
end
