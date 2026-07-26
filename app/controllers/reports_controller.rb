class ReportsController < ApplicationController
  before_action :get_reportable

  def new
    @report = Federails::Moderation::Report.new
  end

  def create
    @report = if @reportable.is_a? Federails::DataEntity
      Federails::Moderation::Report.create report_params.merge({
        federails_actor: current_user&.federails_actor,
        object: @reportable
      })
    else
      Federails::Moderation::Report.create report_params.merge({
        federails_actor: current_user&.federails_actor,
        object: @reportable.federails_actor
      })
    end
    if @reportable.is_a? Comment
      redirect_to(@reportable.commentable, notice: t(".success"))
    else
      redirect_to(@reportable, notice: t(".success"))
    end
  end

  private

  def report_params
    params.expect(report: [
      :content # i18n-tasks-use t("activerecord.attributes.federails/moderation/report.content")
    ])
  end

  def get_reportable
    # Allowlist for reportable class param.
    # This isn't actually supplied by the user, it comes from the router, but best to be double safe.
    reportable, reportable_param = {
      "Model" => [Model, "model_id"],
      "Creator" => [Creator, "creator_id"],
      "Collection" => [Collection, "collection_id"],
      "Comment" => [Comment, "comment_id"]
    }[params[:reportable_class]]
    raise ActionController::BadRequest unless reportable

    id = params[reportable_param]
    @reportable = policy_scope(reportable).find_param(id)
    authorize :"federails/moderation/report"
  end
end
