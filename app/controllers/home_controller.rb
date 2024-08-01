class HomeController < ApplicationController
  include ModelFilters
  before_action :check_library_exists
  skip_after_action :verify_policy_scoped

  def index
    @feed = current_user.actor.activities.order(created_at: :desc).limit(20)
  end

  private

  def check_library_exists
    redirect_to new_library_path if Library.count === 0
  end
end
