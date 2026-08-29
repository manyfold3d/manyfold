# frozen_string_literal: true

# Polls SDCP status for an active PrintJob and finalizes on terminal printer states.
# Never auto-starts the next queued job (GR-002).
class PollPrintJobStatusJob < ApplicationJob
  queue_as :default

  COMPLETE_STATUS = 9
  STOPPED_STATUS = 8

  def perform(print_job_id)
    print_job = PrintJob.find(print_job_id)
    return if print_job.terminal?

    sdcp = print_job.print_host.service
    dto = sdcp.normalized_status

    attrs = {}
    attrs[:current_layer] = dto[:current_layer] if dto[:current_layer]
    attrs[:layer_count] = dto[:total_layers] if dto[:total_layers] && print_job.layer_count.blank?
    print_job.update!(attrs) if attrs.any?

    case dto[:print_status].to_i
    when COMPLETE_STATUS
      Print::JobService.new(print_host: print_job.print_host, actor: nil, sdcp: sdcp)
        .finalize!(print_job, outcome: :succeeded)
    when STOPPED_STATUS
      Print::JobService.new(print_host: print_job.print_host, actor: nil, sdcp: sdcp)
        .finalize!(print_job, outcome: :failed, failure_note: "Printer reported stopped (error #{dto[:error_number]})")
    else
      # Re-enqueue while still active — controllers/SPEC-004 may drive cadence differently.
      self.class.set(wait: 15.seconds).perform_later(print_job_id) if print_job.printing? || print_job.paused?
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("PollPrintJobStatusJob: #{e.message}")
  end
end
