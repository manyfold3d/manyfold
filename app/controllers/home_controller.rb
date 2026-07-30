class HomeController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_before_action :set_up_first_library, only: [:about]

  def index
    @feed = local_timeline
  end

  def welcome
    skip_authorization
  end

  def about
    skip_authorization
  end

  private

  def local_timeline
    [Model, Creator, Collection].map do |model|
      query = policy_scope(model)
      query = query.includes(:fedipub_actor) if SiteSettings.federation_enabled?
      query.order(updated_at: :desc).limit(20)
    end.flatten.sort_by(&:updated_at).last(20).reverse
  end
end
