class HomeController < ApplicationController
  include ModelFilters
  before_action :check_library_exists

  def index
    @recent = policy_scope(Model).recent.limit(20)
    # Eager load for performance
    @recent = @recent.includes([:library, :model_files])
  end

  private

  def check_library_exists
    redirect_to new_library_path if Library.count === 0
  end
end
