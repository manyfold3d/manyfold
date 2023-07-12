class ProblemsController < ApplicationController
  def index
    page = params[:page] || 1
    @problems = Problem.all.page(page).per(50).order([:category, :problematic_type])
  end
end
