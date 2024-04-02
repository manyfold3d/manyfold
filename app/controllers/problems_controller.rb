class ProblemsController < ApplicationController
  def index
    # Are we showing ignored problems?
    @show_ignored = (params[:show_ignored] == "true")
    query = @show_ignored ? policy_scope(Problem.unscoped) : policy_scope(Problem)
    # Now, which page are we on?
    page = params[:page] || 1
    # What categories are we showing?
    # First, get the possible categories based on severity filter
    severities = params[:severity] ? Problem::CATEGORIES.select { |cat| params[:severity]&.include?(current_user.problem_severity(cat).to_s) } : nil
    # Then get the category filter
    categories = params[:category]&.map(&:to_sym)
    # Now query with the intersection of the two, or if we don't have both, then whichever we do have
    if categories.present? || severities.present?
      combined = (categories.present? && severities.present?) ?
        (categories.intersection(severities)) :
        [[categories], [severities]].flatten.compact
      query = query.where(category: combined)
    end
    # What object types are we showing?
    query = query.where(problematic_type: params[:type].map(&:classify)) if params[:type]
    # Don't show types ignored in user settings
    query = query.visible(current_user.problem_settings)
    @problems = query.page(page).per(50).order([:category, :problematic_type])
    # Do we have any filters at all?
    @filters_applied = [:show_ignored, :severity, :category, :type].any? { |k| params.has_key?(k) }
  end

  def update
    @problem = Problem.unscoped.find(params[:id])
    authorize @problem
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
