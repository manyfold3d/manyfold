# frozen_string_literal: true

# Fleet card — status arrives async via printer-fleet Stimulus (INIT-009/SPEC-004).
class Components::PrinterCard < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::NumberToPercentage

  register_value_helper :policy

  def initialize(printer:, status: nil, status_url: nil, snapshot_url: nil)
    @printer = printer
    @status = status.is_a?(Hash) ? status.with_indifferent_access : {}
    @status_url = status_url
    @snapshot_url = snapshot_url
  end

  def view_template
    article(**card_attrs) do
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

  def card_attrs
    attrs = {class: "bg-[#1a1311] border border-[#332623] rounded-2xl overflow-hidden flex flex-col"}
    return attrs if @status_url.blank?

    attrs.merge(
      data: {
        controller: "printer-fleet",
        printer_fleet_status_url_value: @status_url,
        printer_fleet_labels_value: status_labels.to_json
      }
    )
  end

  def status_labels
    {
      idle: t("printers.status.idle"),
      offline: t("printers.status.offline"),
      paused: t("printers.status.paused"),
      printing: t("printers.status.printing"),
      unsupported: t("printers.status.unsupported"),
      no_active_job: t("printers.card.no_active_job"),
      camera_offline: t("printers.card.camera_offline"),
      offline_duration: t("printers.card.offline_duration"),
      eta_unknown: t("printers.card.eta_unknown"),
      live: t("printers.card.live"),
      standby: t("printers.card.standby")
    }
  end

  def camera_region
    div(class: "relative bg-black h-[220px] flex flex-col items-center justify-center overflow-hidden") do
      if @printer.unsupported_for_send?
        Icon(icon: "camera-video", label: t("printers.card.camera_alt", name: @printer.name))
      elsif async_status?
        camera_async
      elsif offline? || @status[:error].present?
        Icon(icon: "wifi-off", label: t("printers.card.camera_offline"))
        p(class: "font-mono text-[11px] text-secondary-500 mt-2 tracking-wide") { t("printers.card.camera_offline") }
      elsif @snapshot_url.present?
        camera_online_snapshot
      else
        Icon(icon: "camera-video", label: t("printers.card.camera_alt", name: @printer.name))
      end
    end
  end

  def camera_async
    div(
      class: "hidden flex flex-col items-center justify-center absolute inset-0",
      data: {printer_fleet_target: "cameraOffline"}
    ) do
      Icon(icon: "wifi-off", label: t("printers.card.camera_offline"))
      p(class: "font-mono text-[11px] text-secondary-500 mt-2 tracking-wide") { t("printers.card.camera_offline") }
    end
    if @snapshot_url.present?
      img(
        src: @snapshot_url,
        alt: t("printers.card.camera_alt", name: @printer.name),
        class: "absolute inset-0 size-full object-cover",
        data: {printer_fleet_target: "snapshot", printer_id: @printer.id}
      )
      div(class: "absolute top-3 left-3 right-3 flex items-start justify-between", data: {printer_fleet_target: "liveBadge"}) do
        span(class: "inline-flex items-center bg-white/10 text-secondary-300 text-[10px] font-mono px-2 py-0.5 rounded") do
          plain t("printers.card.standby")
        end
      end
    else
      Icon(icon: "camera-video", label: t("printers.card.camera_alt", name: @printer.name))
    end
  end

  def camera_online_snapshot
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
  end

  def title_row
    div(class: "flex items-center justify-between gap-3") do
      h2(class: "text-lg font-semibold text-surface m-0 truncate") { @printer.name }
      if async_status?
        span(
          class: badge_wrapper_class("idle"),
          data: {printer_fleet_target: "badge"}
        ) do
          span(class: "size-1.5 rounded-full shrink-0 bg-secondary-400", aria: {hidden: true}, data: {printer_fleet_target: "badgeDot"})
          span(data: {printer_fleet_target: "badgeLabel"}) { t("printers.status.idle") }
        end
      else
        render Components::PrinterStatusBadge.new(status: badge_status)
      end
    end
  end

  def job_meta
    div(class: "flex flex-col gap-2") do
      p(class: "font-mono text-[11px] text-secondary-500 m-0 uppercase tracking-wide") { meta_line }
      summary_attrs = {class: "text-sm m-0 #{offline? ? "text-danger" : "text-secondary-300"}"}
      summary_attrs[:data] = {printer_fleet_target: "summary"} if async_status?
      p(**summary_attrs) { async_status? ? t("printers.card.no_active_job") : job_summary }
      div(class: "bg-[#2f2723] h-1.5 rounded-full overflow-hidden") do
        bar_attrs = {class: "bg-primary-600 h-full", style: "width: #{async_status? ? 0 : progress_pct}%"}
        bar_attrs[:data] = {printer_fleet_target: "bar"} if async_status?
        div(**bar_attrs)
      end
      eta_attrs = {class: "text-xs text-secondary-500 m-0"}
      eta_attrs[:data] = {printer_fleet_target: "eta"} if async_status?
      p(**eta_attrs) { async_status? ? t("printers.card.no_active_job") : eta_line }
    end
  end

  def async_status?
    @status_url.present?
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

  # Mirror Components::PrinterStatusBadge wrapper classes for Stimulus updates.
  def badge_wrapper_class(status)
    base = "inline-flex items-center gap-1.5 px-2 py-1 rounded text-[11px] font-medium"
    case status
    when "printing"
      "#{base} bg-primary-50 text-success dark:bg-primary-950/40 dark:text-success"
    when "paused"
      "#{base} bg-warning/20 text-warning"
    when "unsupported"
      "#{base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400"
    when "offline"
      "#{base} bg-secondary-100 text-secondary-500 dark:bg-secondary-800 dark:text-secondary-500"
    else
      "#{base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400"
    end
  end
end
