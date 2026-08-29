# frozen_string_literal: true

class Components::PrinterCard < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::NumberToPercentage

  register_value_helper :policy

  def initialize(printer:, status: nil, snapshot_url: nil)
    @printer = printer
    @status = status.is_a?(Hash) ? status.with_indifferent_access : {}
    @snapshot_url = snapshot_url
  end

  def view_template
    article(class: "bg-[#1a1311] border border-[#332623] rounded-2xl overflow-hidden flex flex-col") do
      camera_region
      div(class: "flex flex-col gap-4 p-5") do
        title_row
        job_meta
        link_to t("printers.card.open_monitor"),
          printer_path(@printer),
          class: "inline-flex items-center justify-center w-full px-4 py-2 rounded-lg bg-surface border border-secondary-300 text-secondary-900 text-sm font-medium no-underline hover:bg-secondary-50"
      end
    end
  end

  private

  def camera_region
    div(class: "relative bg-black h-[220px] flex flex-col items-center justify-center overflow-hidden") do
      if offline? || @status[:error].present?
        Icon(icon: "wifi-off", label: t("printers.card.camera_offline"))
        p(class: "font-mono text-[11px] text-secondary-500 mt-2 tracking-wide") { t("printers.card.camera_offline") }
      elsif @snapshot_url.present?
        img(
          src: @snapshot_url,
          alt: t("printers.card.camera_alt", name: @printer.name),
          class: "absolute inset-0 size-full object-cover",
          data: {printer_fleet_target: "snapshot", printer_id: @printer.id}
        )
        div(class: "absolute top-3 left-3 right-3 flex items-start justify-between") do
          if printing?
            span(class: "inline-flex items-center gap-1.5 bg-danger/20 text-danger text-[10px] font-mono font-semibold px-2 py-0.5 rounded") do
              span(class: "size-1.5 rounded-full bg-danger", aria: {hidden: true})
              plain t("printers.card.live")
            end
          else
            span(class: "inline-flex items-center bg-white/10 text-secondary-300 text-[10px] font-mono px-2 py-0.5 rounded") do
              plain t("printers.card.standby")
            end
          end
        end
      else
        Icon(icon: "camera-video", label: t("printers.card.camera_alt", name: @printer.name))
      end
    end
  end

  def title_row
    div(class: "flex items-center justify-between gap-3") do
      h2(class: "text-lg font-semibold text-surface m-0 truncate") { @printer.name }
      render Components::PrinterStatusBadge.new(status: badge_status)
    end
  end

  def job_meta
    div(class: "flex flex-col gap-2") do
      p(class: "font-mono text-[11px] text-secondary-500 m-0 uppercase tracking-wide") { meta_line }
      p(class: "text-sm m-0 #{offline? ? "text-danger" : "text-secondary-300"}") { job_summary }
      div(class: "bg-[#2f2723] h-1.5 rounded-full overflow-hidden") do
        div(class: "bg-primary-600 h-full", style: "width: #{progress_pct}%")
      end
      p(class: "text-xs text-secondary-500 m-0") { eta_line }
    end
  end

  def meta_line
    if @printer.unsupported_for_send?
      t("printers.card.meta_unsupported", brand: @printer.brand.presence || "bambu")
    else
      t("printers.card.meta_sdcp", endpoint: @printer.endpoint_host_port)
    end
  end

  def job_summary
    return @status[:error].to_s if offline? && @status[:error].present?
    return t("printers.card.unsupported_note") if @printer.unsupported_for_send?

    filename = @status[:filename].presence
    if printing? && filename
      layers = layer_label
      pct = progress_pct
      t("printers.card.job_printing", filename: filename, percent: pct, layers: layers)
    elsif printing?
      t("printers.status.printing")
    else
      t("printers.card.no_active_job")
    end
  end

  def eta_line
    return t("printers.card.offline_duration") if offline?
    return t("printers.card.no_active_job") unless printing?

    seconds = @status[:eta_seconds]
    return t("printers.card.eta_unknown") if seconds.blank?

    t("printers.card.eta_remaining", duration: format_duration(seconds.to_i))
  end

  def badge_status
    return "unsupported" if @printer.unsupported_for_send?
    return "offline" if offline?
    return "paused" if @status[:print_status].to_i == 2 # SDCP paused heuristic
    return "printing" if printing?

    "idle"
  end

  def offline?
    @status[:error].present? || @status[:unsupported]
  end

  def printing?
    return false if offline? || @printer.unsupported_for_send?

    current = @status[:current_layer]
    total = @status[:total_layers]
    filename = @status[:filename]
    (current.present? && total.present? && total.to_i.positive?) || filename.present?
  end

  def progress_pct
    current = @status[:current_layer].to_f
    total = @status[:total_layers].to_f
    return 0 if total <= 0

    ((current / total) * 100).round.clamp(0, 100)
  end

  def layer_label
    "#{@status[:current_layer]}/#{@status[:total_layers]}"
  end

  def format_duration(seconds)
    return "—" if seconds < 0

    hours = seconds / 3600
    mins = (seconds % 3600) / 60
    if hours.positive?
      t("printers.card.duration_hm", hours: hours, minutes: mins)
    else
      t("printers.card.duration_m", minutes: mins)
    end
  end
end
