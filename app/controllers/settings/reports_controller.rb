class Settings::ReportsController < ApplicationController
  before_action :get_report, only: [:show, :update]
  respond_to :html

  def index
    @reports = policy_scope(Federails::Moderation::Report).where(resolution: nil)
    render layout: "settings"
  end

  def show
    render layout: "settings"
  end

  def update
    if params[:resolve]
      @report.resolve!
      redirect_to settings_reports_path, notice: t(".resolved")
    elsif params[:ignore]
      @report.ignore!
      redirect_to settings_reports_path, notice: t(".ignored")
    else
      redirect_to settings_report_path(@report)
    end
  end

  private

  def get_report
    @report = Federails::Moderation::Report.find(params[:id])
    authorize @report
  end
end
