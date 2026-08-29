# frozen_string_literal: true

module Models
  # Per-model print log: sliced artifacts + history (REQ-010).
  class PrintLogsController < ApplicationController
    include PrintApi

    respond_to :json

    before_action :load_model
    skip_after_action :verify_policy_scoped

    def show
      authorize PrintJob, :index?
      authorize @model, :show?

      artifacts = @model.sliced_artifacts.includes(:print_host, :model_file).order(created_at: :desc)
      jobs = policy_scope(@model.print_jobs).history.includes(:print_host).order(finished_at: :desc)
      succeeded = jobs.where(state: :succeeded).count
      total = jobs.count

      render json: {
        model_id: @model.to_param,
        sliced_artifacts: artifacts.map { |a| serialize_artifact(a) },
        histories: jobs.limit(50).map { |j| serialize_print_job(j) },
        success_widget: {
          succeeded: succeeded,
          total: total,
          success_rate: total.zero? ? 0.0 : (succeeded.to_f / total).round(4)
        }
      }
    end

    private

    def load_model
      @model = policy_scope(Model).find_param(params[:model_id])
    end

    def serialize_artifact(artifact)
      {
        id: artifact.id,
        format: artifact.format,
        print_host_id: artifact.print_host_id,
        model_file_id: artifact.model_file_id,
        estimated_layers: artifact.estimated_layers,
        estimated_duration_seconds: artifact.estimated_duration_seconds,
        estimated_resin_ml: artifact.estimated_resin_ml,
        created_at: artifact.created_at
      }
    end
  end
end
