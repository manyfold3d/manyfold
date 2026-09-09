class ProblemsController < ApplicationController
  skip_after_action :verify_authorized, only: :resolve
  after_action :verify_policy_scoped, only: :resolve

  def index
    authorize Problem
    # Are we showing ignored problems?
    @show_ignored = (params[:show_ignored] == "true")
    query = @show_ignored ? policy_scope(Problem.including_ignored) : policy_scope(Problem)
    # Now, which page are we on?
    page = params[:page] || 1
    # What categories are we showing?
    # First, get the possible categories based on severity filter
    severities = params[:severity] ? Problem::CATEGORIES.select { |cat| params[:severity]&.include?(current_user.problem_severity(cat).to_s) } : nil # rubocop:disable Pundit/UsePolicyScope
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
    query = query.visible(helpers.problem_settings)
    query = query.includes([:problematic])
    @counts_by_category = query.unscope(:includes, :order).group(:category).count
    @problems = query.page(page).per(params[:per_page]&.to_i || 50).order([:category, :problematic_type]).includes(problematic: [:library, :model])
    @duplicate_list = @problems.any? && @problems.all? { |problem| problem.category == "duplicate" }
    @recoverable_bytes = recoverable_bytes_for(@problems)
    # Do we have any filters at all?
    @filters_applied = [:show_ignored, :severity, :category, :type].any? { |k| params.has_key?(k) }
  end

  def update
    @problem = Problem.including_ignored.find_param(params[:id])
    authorize @problem
    @problem.update!(permitted_params)
    notice = t(
      (@problem.ignored ? ".ignored" : ".unignored"),
      name: @problem.problematic.name,
      message: translate("problems.%{type}.%{category}.title" % {type: @problem.problematic_type.underscore, category: @problem.category})
    )
    redirect_back_or_to problems_path, notice: notice
  end

  def resolve
    ids = params[:id] ? [params[:id]] : params["problems"]&.select { |_k, v| v == "1" }&.keys || []
    @problems = policy_scope(Problem).where(public_id: ids).to_a
    bulk = @problems.size > 1

    if params[:resolve]
      result = Problem.resolve_batch(@problems)
      handle_resolve_result(result, bulk)
    elsif params[:ignore]
      result = Problem.resolve_batch(@problems, override_action: :ignore)
      handle_resolve_result(result, bulk)
    else
      redirect_back_or_to problems_path unless performed?
    end
  end

  private

  def handle_resolve_result(result, bulk)
    if result[:redirect].present? && !bulk && !performed?
      redirect_to result[:redirect]
      return
    end

    ids_to_remove = result[:removed_ids] + result[:ignored_ids]
    if request.format.turbo_stream? && ids_to_remove.any? && !performed?
      render turbo_stream: build_resolve_turbo_streams(ids_to_remove)
      return
    end

    redirect_back_or_to problems_path unless performed?
  end

  def build_resolve_turbo_streams(ids_to_remove)
    streams = ids_to_remove.map { |id| turbo_stream.remove("problem-#{id}") }
    # When resolving from the model page, replace the problems card so the count updates.
    if params[:from] == "model" && params[:model_id].present?
      model = Model.find_by(public_id: params[:model_id])
      if model && policy(:problem).show?
        streams << turbo_stream.replace("model-problems-card", partial: "application/problems_card", locals: {
          problematic: model,
          problems: model.problems.visible(helpers.problem_settings),
          show_when_empty: true,
          card_id: "model-problems-card",
          from_model: model,
          nesting_models: (model.contained_models if model.contains_other_models?)
        })
      end
    end
    streams
  end

  def permitted_params
    params.expect(problem: [
      :ignored
    ])
  end

  def recoverable_bytes_for(problems)
    file_ids = problems.filter_map { |problem| problem.problematic_id if problem.problematic_type == "ModelFile" }
    return 0 if file_ids.empty?

    policy_scope(ModelFile).where(id: file_ids).sum(:size).to_i
  end
end
