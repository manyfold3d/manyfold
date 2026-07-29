class ReportsController < ApplicationController
  before_action :get_reportable

  def new
    @report = Fedipub::Moderation::Report.new
  end

  def create
    @report = if @reportable.is_a? Fedipub::DataEntity
      Fedipub::Moderation::Report.create report_params.merge({
        _actor: current_user&.fedipub_actor,
        object: @reportable
      })
    else
      Fedipub::Moderation::Report.create report_params.merge({
        fedipub_actor: current_user&.fedipub_actor,
        object: @reportable.fedipub_actor
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
      :content # i18n-tasks-use t("activerecord.attributes.fedipub/moderation/report.content")
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
    authorize :"fedipub/moderation/report"
  end
end
