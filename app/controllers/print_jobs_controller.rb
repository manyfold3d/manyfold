# frozen_string_literal: true

# Queue board + job control (REQ-006, REQ-009).
class PrintJobsController < ApplicationController
  include PrintApi

  respond_to :json

  before_action :load_print_job, only: [:show, :start, :pause, :resume, :cancel, :confirm_plate_cleared]

  def index
    authorize PrintJob
    jobs = policy_scope(PrintJob).includes(:print_host, :model, :sliced_artifact)
    jobs = jobs.where(print_host_id: params[:print_host_id]) if params[:print_host_id].present?

    render json: {
      queue: {
        queued: jobs.where(state: %w[queued waiting_plate]).order(:created_at).map { |j| serialize_print_job(j) },
        printing: jobs.where(state: %w[printing paused]).order(:started_at).map { |j| serialize_print_job(j) },
        completed: jobs.where(state: PrintJob::TERMINAL_STATES).order(finished_at: :desc).limit(50).map { |j| serialize_print_job(j) }
      }
    }
  end

  def show
    authorize @print_job
    render json: {print_job: serialize_print_job(@print_job)}
  end

  def create
    authorize PrintJob
    print_host = policy_scope(PrintHost).find(print_job_params[:print_host_id])
    authorize print_host, :control?

    attrs = print_job_create_attrs
    job = job_service_for(print_host).create!(attrs)
    render json: {print_job: serialize_print_job(job)}, status: :created
  rescue Print::JobService::GateFailed => e
    render_gate_failure(e.result)
  rescue Print::JobService::Error, ActiveRecord::RecordInvalid => e
    render_print_error(e)
  end

  def start
    authorize @print_job, :start?
    confirm = ActiveModel::Type::Boolean.new.cast(params[:confirm])
    job_service_for(@print_job.print_host).start!(
      @print_job,
      confirm: confirm,
      filename: params[:filename],
      start_layer: params.fetch(:start_layer, 0).to_i
    )
    render json: {print_job: serialize_print_job(@print_job.reload)}
  rescue Print::JobService::GateFailed => e
    render_gate_failure(e.result)
  rescue Print::JobService::ConfirmationRequired, Print::JobService::PlateNotCleared,
    Print::JobService::Busy, Print::JobService::InvalidState, Print::JobService::Error => e
    render_print_error(e)
  rescue Print::SdcpService::Error => e
    render_print_error(e)
  end

  def pause
    authorize @print_job, :pause?
    job_service_for(@print_job.print_host).pause!(@print_job)
    render json: {print_job: serialize_print_job(@print_job.reload)}
  rescue Print::JobService::InvalidState, Print::JobService::Error, Print::SdcpService::Error => e
    render_print_error(e)
  end

  def resume
    authorize @print_job, :resume?
    job_service_for(@print_job.print_host).resume!(@print_job)
    render json: {print_job: serialize_print_job(@print_job.reload)}
  rescue Print::JobService::Busy, Print::JobService::InvalidState, Print::JobService::Error, Print::SdcpService::Error => e
    render_print_error(e)
  end

  def cancel
    authorize @print_job, :cancel?
    job_service_for(@print_job.print_host).cancel!(@print_job, note: params[:note])
    render json: {print_job: serialize_print_job(@print_job.reload)}
  rescue Print::JobService::InvalidState, Print::JobService::Error, Print::SdcpService::Error => e
    render_print_error(e)
  end

  def confirm_plate_cleared
    authorize @print_job, :confirm_plate_cleared?
    job_service_for(@print_job.print_host).confirm_plate_cleared!(@print_job)
    render json: {print_job: serialize_print_job(@print_job.reload)}
  rescue Print::JobService::InvalidState, Print::JobService::Error => e
    render_print_error(e)
  end

  private

  def load_print_job
    @print_job = policy_scope(PrintJob).find(params[:id])
  end

  def print_job_params
    params.expect(print_job: [
      :print_host_id, :model_id, :model_file_id, :sliced_artifact_id,
      :resin_profile, :layer_count, :estimated_duration_seconds, :estimated_resin_ml,
      {stamp: [:format, :resolution_w, :resolution_h, :z_height_mm, :aa]}
    ])
  end

  def print_job_create_attrs
    raw = print_job_params.to_h.symbolize_keys
    stamp = raw.delete(:stamp)
    attrs = raw
    attrs[:stamp] = stamp if stamp.present?
    if attrs[:sliced_artifact_id].present?
      attrs[:sliced_artifact] = SlicedArtifact.find(attrs.delete(:sliced_artifact_id))
    end
    if attrs[:model_id].present?
      attrs[:model] = Model.find_param(attrs.delete(:model_id))
    end
    if attrs[:model_file_id].present?
      attrs[:model_file] = ModelFile.find_param(attrs.delete(:model_file_id))
    end
    attrs
  end
end
