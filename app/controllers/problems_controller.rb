class ProblemsController < ApplicationController
  def index
    @show_ignored = (params[:show_ignored] == "true")
    page = params[:page] || 1
    query = @show_ignored ? Problem.unscoped : Problem
    @problems = query.visible(current_user.problem_settings).page(page).per(50).order([:category, :problematic_type])
  end

  def update
    @problem = Problem.unscoped.find(params[:id])
    @problem.update!(permitted_params)
    flash[:notice] = t(
      (@problem.ignored ? ".ignored" : ".unignored"),
      name: @problem.problematic.name,
      message: t("problems.%{type}_%{category}.title" % {type: @problem.problematic_type.underscore, category: @problem.category})
    )
    redirect_back_or_to problems_path
  end

  private

  def permitted_params
    params.require(:problem).permit([
      :ignored
    ])
  end
end
