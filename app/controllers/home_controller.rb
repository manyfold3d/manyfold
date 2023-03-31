class HomeController < ApplicationController
  include ModelFilters
  before_action :check_for_first_use

  def index
    @recent = Model.recent.limit(20)
  end

  private

  def check_for_first_use
    redirect_to new_library_path if Library.count === 0
  end
end
