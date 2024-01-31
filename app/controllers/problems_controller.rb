class ProblemsController < ApplicationController
  def index
    page = params[:page] || 1
    @problems = Problem.visible(current_user.problem_settings).page(page).per(50).order([:category, :problematic_type])
  end

  def update
    @problem = Problem.find(params[:id])
    @problem.update!(permitted_params)
    flash[:notice] = t(".ignored", name: @problem.problematic.name,
      message: t("problems.%{type}_%{category}.title" % {type: @problem.problematic_type.underscore, category: @problem.category}))
    redirect_to problems_path
  end

  private

  def permitted_params
    params.require(:problem).permit([
      :ignored
    ])
  end
end
