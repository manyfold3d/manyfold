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
    # if @domain_block.valid?
    #   redirect_to settings_domain_blocks_path, notice: t(".success")
    # else
    #   render "new", layout: "settings", status: :unprocessable_entity
    # end
  end

  private

  def get_report
    @report = Federails::Moderation::Report.find(params[:id])
    authorize @report
  end
end
