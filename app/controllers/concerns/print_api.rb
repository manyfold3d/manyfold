# frozen_string_literal: true

# Shared JSON helpers for Print Studio manager controllers (INIT-008/SPEC-004).
module PrintApi
  extend ActiveSupport::Concern

  private

  def render_gate_failure(result)
    render json: {
      error: "gate_failed",
      reasons: serialize_gate_reasons(result.reasons)
    }, status: :unprocessable_content
  end

  def render_print_error(error, status: :unprocessable_content)
    body = {error: error.class.name.demodulize.underscore, message: error.message}
    if error.respond_to?(:result) && error.result
      body[:reasons] = serialize_gate_reasons(error.result.reasons)
    end
    render json: body, status: status
  end

  def serialize_gate_reasons(reasons)
    Array(reasons).map do |reason|
      {
        code: reason.code,
        message: reason.message,
        expected: reason.expected,
        actual: reason.actual
      }
    end
  end

  def serialize_printer(host, status: nil)
    {
      id: host.id,
      name: host.name,
      endpoint: host.endpoint,
      protocol: host.protocol,
      mainboard_id: host.mainboard_id,
      brand: host.brand,
      machine_model: host.machine_model,
      firmware: host.firmware,
      mac_address: host.mac_address,
      resolution_w: host.resolution_w,
      resolution_h: host.resolution_h,
      build_x_mm: host.build_x_mm,
      build_y_mm: host.build_y_mm,
      build_z_mm: host.build_z_mm,
      native_formats: host.native_formats,
      capability_formats: host.capability_formats,
      fep_cycles: host.fep_cycles,
      lcd_hours: host.lcd_hours,
      storage_bytes_used: host.storage_bytes_used,
      storage_bytes_total: host.storage_bytes_total,
      status: status
    }
  end

  def serialize_print_job(job)
    {
      id: job.id,
      print_host_id: job.print_host_id,
      model_id: job.model_id,
      model_file_id: job.model_file_id,
      sliced_artifact_id: job.sliced_artifact_id,
      user_id: job.user_id,
      state: job.state,
      plate_cleared_at: job.plate_cleared_at,
      resin_profile: job.resin_profile,
      layer_count: job.layer_count,
      current_layer: job.current_layer,
      estimated_duration_seconds: job.estimated_duration_seconds,
      actual_duration_seconds: job.actual_duration_seconds,
      estimated_resin_ml: job.estimated_resin_ml,
      actual_resin_ml: job.actual_resin_ml,
      outcome: job.history_outcome,
      failure_note: job.failure_note,
      started_at: job.started_at,
      finished_at: job.finished_at,
      created_at: job.created_at,
      updated_at: job.updated_at
    }
  end

  def serialize_resin_bottle(bottle)
    {
      id: bottle.id,
      brand: bottle.brand,
      color: bottle.color,
      remaining_ml: bottle.remaining_ml,
      capacity_ml: bottle.capacity_ml,
      opened_on: bottle.opened_on,
      print_host_id: bottle.print_host_id
    }
  end

  def serialize_print_vat(vat)
    {
      id: vat.id,
      identity: vat.identity,
      fep_cycles: vat.fep_cycles,
      status: vat.status,
      print_host_id: vat.print_host_id,
      resin_bottle_id: vat.resin_bottle_id
    }
  end

  def job_service_for(print_host)
    Print::JobService.new(print_host: print_host, actor: current_user)
  end
end
