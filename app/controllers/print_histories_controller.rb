# frozen_string_literal: true

# Print history + KPIs (REQ-008). History is terminal PrintJob rows.
class PrintHistoriesController < ApplicationController
  include PrintApi

  respond_to :html, :json

  def index
    authorize PrintJob
    jobs = policy_scope(PrintJob).history.includes(:print_host, :model, :model_file)
    jobs = jobs.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?
    jobs = apply_outcome_filter(jobs)
    jobs = apply_date_filter(jobs)

    @kpis = build_kpis(jobs)
    @histories = jobs.limit(params.fetch(:limit, 100).to_i)
    @print_hosts = policy_scope(PrintHost).order(:name)
    @from = params[:from].presence || params[:start_date]
    @to = params[:to].presence || params[:end_date]
    @outcome = params[:outcome].presence || params[:result]
    @print_host_id = params[:print_host_id]

    respond_to do |format|
      format.html
      format.json {
        render json: {
          histories: @histories.map { |j| serialize_print_job(j) },
          kpis: @kpis
        }
      }
      format.csv {
        # Export CSV stub — full CSV lands with analytics follow-up.
        head :not_implemented
      }
    end
  end

  private

  def apply_date_filter(scope)
    from = parse_date(params[:from] || params[:start_date])
    to = parse_date(params[:to] || params[:end_date])
    scope = scope.where(finished_at: from.beginning_of_day..) if from
    scope = scope.where(finished_at: ..to.end_of_day) if to
    scope
  end

  def apply_outcome_filter(scope)
    outcome = params[:outcome].presence || params[:result].presence
    return scope if outcome.blank? || outcome == "all"

    case outcome.to_s
    when "succeeded", "success"
      scope.where(outcome: "succeeded").or(scope.where(state: :succeeded))
    when "failed", "failure"
      scope.where(outcome: "failed").or(scope.where(state: :failed))
    when "cancelled", "canceled"
      scope.where(outcome: "cancelled").or(scope.where(state: :cancelled))
    else
      scope
    end
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def build_kpis(scope)
    total = scope.count
    succeeded = scope.where(outcome: "succeeded").or(scope.where(state: :succeeded)).count
    duration = scope.sum(:actual_duration_seconds).to_i
    resin_ml = scope.sum(:actual_resin_ml).to_d
    {
      jobs: total,
      succeeded: succeeded,
      success_rate: total.zero? ? 0.0 : (succeeded.to_f / total).round(4),
      hours: (duration / 3600.0).round(2),
      resin_liters: (resin_ml / 1000).to_f.round(3)
    }
  end
end
