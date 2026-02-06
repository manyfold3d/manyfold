class HomeController < ApplicationController
  before_action :check_library_exists
  skip_after_action :verify_policy_scoped

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

  def check_library_exists
    redirect_to new_library_path if Library.all.empty? # rubocop:disable Pundit/UsePolicyScope
  end

  def local_timeline
    [Model, Creator, Collection].map do |model|
      query = policy_scope(model)
      query = query.includes(:federails_actor) if SiteSettings.federation_enabled?
      query.order(updated_at: :desc).limit(20)
    end.flatten.sort_by(&:updated_at).last(20).reverse
  end
end
