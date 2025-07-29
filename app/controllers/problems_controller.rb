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
    @problems = query.page(page).per(params[:per_page]&.to_i || 50).order([:category, :problematic_type]).includes(problematic: [:library, :model])
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
    ids = params[:id] ? [params[:id]] : params["problems"].select { |k, v| v == "1" }.keys
    @problems = policy_scope(Problem).where(public_id: ids)
    # Resolve each problem individually
    # Some can't be done in bulk mode, so check that
    bulk = @problems.count > 1
    if params[:resolve]
      @problems.each do |problem|
        case problem.resolution_strategy
        when :show
          resolve_by_showing(problem) unless bulk
        when :edit
          resolve_by_editing(problem) unless bulk
        when :destroy
          resolve_by_destroying(problem)
        when :merge
          resolve_by_merging(problem)
        when :upload
          resolve_by_uploading(problem) unless bulk
        when :convert
          resolve_by_converting(problem)
        else
          raise NotImplementedError
        end
      end
    elsif params[:ignore]
      @problems.update(ignored: true)
    end
    redirect_back_or_to problems_path unless performed?
  end

  private

  def resolve_by_showing(problem)
    case problem.problematic_type
    when "Model"
      redirect_to problem.problematic
    when "ModelFile"
      redirect_to [problem.problematic.model, problem.problematic]
    else
      raise NotImplementedError
    end
  end

  def resolve_by_editing(problem)
    case problem.problematic_type
    when "Library"
      redirect_to edit_library_path(problem.problematic)
    when "Model"
      redirect_to edit_model_path(problem.problematic)
    when "ModelFile"
      redirect_to edit_model_model_file_path([problem.problematic.model, problem.problematic])
    when "Link"
      redirect_to edit_model_path(problem.problematic.linkable)
    else
      raise NotImplementedError
    end
  end

  def resolve_by_destroying(problem)
    case problem.problematic_type
    when "Model"
      problem.problematic.delete_from_disk_and_destroy
    when "ModelFile"
      problem.problematic.delete_from_disk_and_destroy
    else
      raise NotImplementedError
    end
  end

  def resolve_by_merging(problem)
    case problem.problematic_type
    when "Model"
      problem.update(in_progress: true)
      problem.problematic.merge!(problem.problematic.contained_models)
    else
      raise NotImplementedError
    end
  end

  def resolve_by_uploading(problem)
    case problem.problematic_type
    when "Model"
      redirect_to model_path(problem.problematic, anchor: "upload-form")
    else
      raise NotImplementedError
    end
  end

  def resolve_by_converting(problem)
    case problem.problematic_type
    when "ModelFile"
      problem.update(in_progress: true)
      problem.problematic.convert_later :threemf
    else
      raise NotImplementedError
    end
  end

  def permitted_params
    params.expect(problem: [
      :ignored
    ])
  end
end
