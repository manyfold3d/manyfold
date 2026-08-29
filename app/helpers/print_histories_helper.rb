# frozen_string_literal: true

module PrintHistoriesHelper
  def history_job_name(job)
    job.model_file&.filename.presence ||
      job.model&.name.presence ||
      t("print_jobs.card.untitled")
  end

  def history_duration(job)
    actual = format_print_duration(job.actual_duration_seconds)
    estimated = format_print_duration(job.estimated_duration_seconds)
    if job.estimated_duration_seconds.present?
      t("print_histories.index.table.duration_with_est", actual: actual, estimated: estimated)
    else
      actual
    end
  end

  def outcome_dot_class(outcome)
    case outcome.to_s
    when "succeeded", "success" then "bg-success"
    when "failed", "failure" then "bg-danger"
    when "cancelled", "canceled" then "bg-warning"
    else "bg-secondary-500"
    end
  end

  def format_print_duration(seconds)
    return "—" if seconds.blank?

    seconds = seconds.to_i
    hours = seconds / 3600
    mins = (seconds % 3600) / 60
    if hours.positive?
      t("print_jobs.card.duration_hm", hours: hours, minutes: mins)
    else
      t("print_jobs.card.duration_m", minutes: mins)
    end
  end
end
