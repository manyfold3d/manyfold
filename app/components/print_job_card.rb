# frozen_string_literal: true

# Kanban card for Job Queue columns (Figma 13 Job Queue / 23:1441).
# Icons: Bootstrap Icons matching Figma glyphs (alert-triangle → exclamation-triangle,
# move → arrows-move) — MCP asset URLs expire; documented deviation.
class Components::PrintJobCard < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::NumberWithDelimiter

  register_value_helper :policy

  def initialize(job:, column:)
    @job = job
    @column = column.to_sym
  end

  def view_template
    case @column
    when :queued then queued_card
    when :printing then printing_card
    when :completed then completed_card
    else queued_card
    end
  end

  private

  def queued_card
    waiting = @job.waiting_plate?
    article(
      class: "bg-[#1a1311] border #{waiting ? "border-primary-600" : "border-[#332623]"} rounded-xl p-4 flex flex-col gap-3",
      data: {print_queue_target: "card", job_id: @job.id, column: "queued"}
    ) do
      div(class: "flex items-center justify-between gap-2") do
        p(class: "font-semibold text-sm text-surface m-0 truncate") { filename }
        Icon(icon: "arrows-move", label: t("print_jobs.card.reorder"))
      end
      meta_block
      div(class: "flex items-center justify-between gap-2") do
        p(class: "font-mono text-[11px] text-primary-600 m-0") { duration_label(@job.estimated_duration_seconds) }
        p(class: "text-[10px] text-secondary-500 m-0") { attribution }
      end
      if waiting
        div(class: "flex items-center gap-2 p-2 rounded-lg bg-primary-600/10 border border-primary-600") do
          Icon(icon: "exclamation-triangle", label: t("print_jobs.card.waiting_plate"))
          p(class: "font-semibold text-[10px] text-primary-600 m-0") { t("print_jobs.card.waiting_plate") }
        end
      end
    end
  end

  def printing_card
    article(
      class: "bg-[#1a1311] border border-[#332623] rounded-xl p-4 flex flex-col gap-3",
      data: {
        print_queue_target: "card",
        job_id: @job.id,
        column: "printing",
        current_layer: @job.current_layer,
        layer_count: @job.layer_count,
        started_at: @job.started_at&.iso8601
      }
    ) do
      div(class: "flex items-center gap-3") do
        div(class: "size-[50px] rounded-lg bg-secondary-800 flex items-center justify-center shrink-0 overflow-hidden") do
          Icon(icon: "box", label: filename)
        end
        div(class: "min-w-0 flex-1") do
          p(class: "font-semibold text-[13px] text-surface m-0 truncate") { filename }
          p(class: "text-[11px] text-secondary-300 m-0 truncate") { host_name }
        end
      end
      div(class: "flex flex-col gap-1.5") do
        div(class: "flex items-center justify-between text-[11px]") do
          span(class: "text-secondary-300", data: {print_queue_target: "layers"}) { layer_line }
          span(class: "font-mono text-primary-600", data: {print_queue_target: "percent"}) { "#{progress_pct}%" }
        end
        div(class: "bg-[#2f2723] h-1.5 rounded overflow-hidden") do
          div(
            class: "bg-primary-600 h-full transition-[width] duration-500",
            style: "width: #{progress_pct}%",
            data: {print_queue_target: "bar"}
          )
        end
        div(class: "flex items-center justify-between text-[10px] font-mono") do
          span(class: "text-secondary-400") do
            plain t("print_jobs.card.elapsed")
            whitespace
            span(data: {print_queue_target: "elapsed"}) { elapsed_label }
          end
          span(class: "text-primary-600") do
            plain t("print_jobs.card.remaining")
            whitespace
            span(data: {print_queue_target: "remaining"}) { remaining_label }
          end
        end
      end
      if policy(@job).control?
        div(class: "flex items-center gap-3") do
          if @job.printing? && policy(@job).pause?
            button_to t("print_jobs.card.pause"),
              pause_print_job_path(@job),
              method: :post,
              class: "text-sm text-secondary-300 bg-transparent border-0 cursor-pointer p-0 hover:text-surface",
              form: {class: "inline"}
          end
          if policy(@job).cancel?
            button_to t("print_jobs.card.cancel"),
              cancel_print_job_path(@job),
              method: :post,
              class: "inline-flex items-center justify-center px-3 py-1.5 rounded-lg border border-danger text-danger text-sm font-medium bg-transparent",
              form: {class: "inline"},
              data: {turbo_confirm: t("print_jobs.card.confirm_cancel")}
          end
        end
      end
    end
  end

  def completed_card
    outcome = @job.history_outcome.to_s
    needs_clear = @job.succeeded? && @job.plate_cleared_at.blank?
    article(
      class: "bg-[#1a1311] border border-[#332623] rounded-xl p-4 flex flex-col gap-3",
      data: {print_queue_target: "card", job_id: @job.id, column: "completed"}
    ) do
      div(class: "flex items-start justify-between gap-2") do
        p(class: "font-semibold text-sm text-surface m-0 truncate") { filename }
        render Components::PrintOutcomeBadge.new(outcome: outcome)
      end
      p(class: "text-[12px] text-secondary-300 m-0") { host_name }
      p(class: "text-[10px] text-secondary-500 m-0") { finished_label }
      if needs_clear && policy(@job).confirm_plate_cleared?
        button_to t("print_jobs.card.confirm_plate_cleared"),
          confirm_plate_cleared_print_job_path(@job),
          method: :post,
          class: "inline-flex items-center justify-center w-full px-3 py-2 rounded-lg border border-success text-success text-sm font-medium bg-transparent hover:bg-success/10",
          form: {class: "w-full"}
      elsif @job.failed?
        p(class: "text-[11px] text-danger m-0") { @job.failure_note.presence || t("print_jobs.card.reset_diagnostics") }
      end
    end
  end

  def meta_block
    div(class: "flex flex-col gap-1 text-[12px] text-secondary-300") do
      p(class: "m-0") { t("print_jobs.card.target", name: host_name) }
      p(class: "m-0") { t("print_jobs.card.resin", profile: resin_label) }
    end
  end

  def filename
    @job.model_file&.filename.presence ||
      @job.sliced_artifact&.model_file&.filename.presence ||
      t("print_jobs.card.untitled")
  end

  def host_name
    @job.print_host&.name.presence || t("print_jobs.card.unknown_host")
  end

  def resin_label
    @job.resin_profile.presence || t("print_jobs.card.resin_unknown")
  end

  def attribution
    who = @job.user&.username.presence || @job.user&.email.presence || t("print_jobs.card.system")
    when_ago = @job.created_at ? "#{time_ago_in_words(@job.created_at)} #{t("print_jobs.card.ago")}" : ""
    "#{who} · #{when_ago}".strip
  end

  def finished_label
    return t("print_jobs.card.finished_unknown") if @job.finished_at.blank?

    t("print_jobs.card.finished_ago", time: time_ago_in_words(@job.finished_at))
  end

  def layer_line
    current = @job.current_layer
    total = @job.layer_count
    return t("print_jobs.card.layers_unknown") if current.blank? || total.blank?

    t("print_jobs.card.layers", current: number_with_delimiter(current), total: number_with_delimiter(total))
  end

  def progress_pct
    current = @job.current_layer.to_f
    total = @job.layer_count.to_f
    return 0 if total <= 0

    ((current / total) * 100).round.clamp(0, 100)
  end

  def elapsed_label
    return "—" if @job.started_at.blank?

    duration_label((Time.current - @job.started_at).to_i)
  end

  def remaining_label
    return "—" if @job.estimated_duration_seconds.blank? || @job.started_at.blank?

    elapsed = (Time.current - @job.started_at).to_i
    remaining = [@job.estimated_duration_seconds - elapsed, 0].max
    duration_label(remaining)
  end

  def duration_label(seconds)
    return "—" if seconds.blank?

    seconds = seconds.to_i
    hours = seconds / 3600
    mins = (seconds % 3600) / 60
    "#{hours.to_s.rjust(2, "0")}h #{mins.to_s.rjust(2, "0")}m"
  end
end
