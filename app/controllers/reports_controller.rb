class ReportsController < ApplicationController
  before_action :get_reportable

  def new
    @report = Federails::Moderation::Report.new
  end

  def create
    @report = Federails::Moderation::Report.create report_params.merge({
      federails_actor: current_user&.federails_actor,
      object: @reportable.federails_actor
    })
    redirect_to(@reportable, notice: t(".success"))
  end

  private

  def report_params
    params.expect(report: [
      :content
    ])
  end

  def get_reportable
    reportable = params[:reportable_class].constantize
    reportable_param = params[:reportable_class].parameterize + "_id"
    id = params[reportable_param]
    @reportable = policy_scope(reportable).find_param(id)
    authorize :"federails/moderation/report"
  end
end
