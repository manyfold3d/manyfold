class ProblemsController < ApplicationController
  def index
    # Are we showing ignored problems?
    @show_ignored = (params[:show_ignored] == "true")
    query = @show_ignored ? Problem.unscoped : Problem
    # Now, which page are we on?
    page = params[:page] || 1
    # What categories are we showing?
    query = query.where(category: params[:category].map(&:to_sym)) if params[:category]
    # What object types are we showing?
    query = query.where(problematic_type: params[:type].map(&:classify)) if params[:type]
    # Don't show types ignored in user settings
    query = query.visible(current_user.problem_settings)
    @problems = query.page(page).per(50).order([:category, :problematic_type])
  end

  def update
    @problem = Problem.unscoped.find(params[:id])
    @problem.update!(permitted_params)
    notice = t(
      (@problem.ignored ? ".ignored" : ".unignored"),
      name: @problem.problematic.name,
      message: t("problems.%{type}_%{category}.title" % {type: @problem.problematic_type.underscore, category: @problem.category})
    )
    redirect_back_or_to problems_path, notice: notice
  end

  private

  def permitted_params
    params.require(:problem).permit([
      :ignored
    ])
  end
end
