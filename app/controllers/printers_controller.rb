# frozen_string_literal: true

# Print Studio fleet UI + JSON API (INIT-008/SPEC-004 + SPEC-005).
# Settings::PrintHosts remains for admin settings CRUD; this surface is first-class.
class PrintersController < ApplicationController
  include PrintApi

  respond_to :html, :json

  before_action :load_printer, only: [
    :show, :update, :status, :snapshot, :settings, :pause, :stop, :continue, :send_file
  ]
  skip_after_action :verify_policy_scoped, only: [:discover, :new]

  def index
    authorize PrintHost
    @printers = policy_scope(PrintHost).order(:name)
    respond_to do |format|
      format.html do
        @statuses = {}
        @printers.each { |host| @statuses[host.id] = fetch_status(host) }
      end
      format.json {
        render json: {printers: @printers.map { |host| serialize_printer(host) }}
      }
    end
  end

  def show
    authorize @printer
    @status = fetch_status(@printer)
    @queue_jobs = policy_scope(PrintJob)
      .includes(:model_file)
      .where(print_host_id: @printer.id)
      .where(state: %w[queued waiting_plate printing paused])
      .order(:created_at)
      .limit(20)
    respond_to do |format|
      format.html
      format.json { render json: {printer: serialize_printer(@printer, status: @status)} }
    end
  end

  def new
    authorize PrintHost
    @printer = PrintHost.new(protocol: Print::SdcpService::PROTOCOL)
    @candidates = []
  end

  def create
    authorize PrintHost
    @printer = PrintHost.new(printer_params)
    @printer.protocol = Print::SdcpService::PROTOCOL
    respond_to do |format|
      if @printer.save
        format.html { redirect_to printer_path(@printer), notice: t(".success") }
        format.json { render json: {printer: serialize_printer(@printer)}, status: :created }
      else
        format.html {
          @candidates = []
          render :new, status: :unprocessable_content
        }
        format.json { render json: {errors: @printer.errors.to_hash}, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @printer
    respond_to do |format|
      if @printer.update(printer_params)
        format.json { render json: {printer: serialize_printer(@printer)} }
        format.html { redirect_to settings_printer_path(@printer), notice: t(".updated") }
      else
        format.json { render json: {errors: @printer.errors.to_hash}, status: :unprocessable_content }
        format.html {
          @status = fetch_status(@printer)
          @storage_files = []
          @storage_error = nil
          @gate_rules = build_gate_checklist(@printer)
          render :settings, status: :unprocessable_content
        }
      end
    end
  end

  def destroy
    authorize @printer
    @printer.destroy!
    respond_to do |format|
      format.html { redirect_to printers_path, notice: t(".destroyed") }
      format.json { head :no_content }
    end
  end

  # UDP discover — returns candidates only; never persists (REQ-003).
  def discover
    authorize PrintHost, :discover?
    hosts = Array(params[:hosts].presence || ["255.255.255.255"])
    timeout = (params[:timeout].presence || 2.0).to_f
    @candidates = Print::SdcpService.discover_candidates(hosts: hosts, timeout: timeout)
    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "printers/discoveries", locals: {candidates: @candidates} }
      format.json { render json: {candidates: @candidates} }
    end
  rescue Print::SdcpService::Error => e
    respond_to do |format|
      format.turbo_stream { head :unprocessable_content }
      format.html { render plain: e.message, status: :unprocessable_content }
      format.json { render json: {error: e.message}, status: :unprocessable_content }
    end
  end

  # Printer Settings UI — identity, storage, gate checklist, camera (INIT-008/SPEC-007 · REQ-012).
  def settings
    authorize @printer
    @status = fetch_status(@printer)
    @storage_files = []
    @storage_error = nil
    @storage_bytes_free = nil
    unless @printer.unsupported_for_send?
      begin
        svc = @printer.service
        @storage_files = Array(svc.list_files(url: "/local"))
        @storage_bytes_free = svc.storage_free_bytes
      rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
        @storage_error = e.message
      end
    end
    @gate_rules = build_gate_checklist(@printer)
  end

  def status
    authorize @printer, :show?
    render json: {status: fetch_status!(@printer)}
  rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
    render json: {error: e.message}, status: :bad_gateway
  end

  # Authenticated JPEG proxy — browsers never talk to go2rtc ClusterIP directly.
  def snapshot
    authorize @printer, :show?
    jpeg = Print::Go2rtcClient.frame_jpeg(stream: camera_stream_name)
    send_data jpeg, type: "image/jpeg", disposition: "inline"
  rescue Print::Go2rtcClient::Error => e
    Rails.logger.warn("[Printers#snapshot] #{e.class}: #{e.message}")
    head :bad_gateway
  end

  def pause
    control_command!(:pause_print, :pause)
  end

  def stop
    control_command!(:stop_print, :stop)
  end

  def continue
    control_command!(:continue_print, :continue)
  end

  # Library send path — sliced ModelFile only; gate must pass (REQ-004).
  def send_file
    authorize @printer, :control?
    model = policy_scope(Model).find_param(params.require(:model_id))
    file = policy_scope(model.model_files).find_param(params.require(:model_file_id))
    authorize file, :show?

    unless file.sliced_for_print?
      redirect_back_or_to model_model_file_path(model, file),
        alert: t(".format_not_sliced")
      return
    end
    extension = file.extension.to_s.downcase

    if @printer.unsupported_for_send?
      redirect_back_or_to model_model_file_path(model, file),
        alert: t(".unsupported_printer")
      return
    end

    stamp = {format: extension}
    gate = Print::CompatibilityGate.call(print_host: @printer, stamp: stamp)
    unless gate.pass?
      messages = gate.reasons.map(&:message).join("; ")
      redirect_back_or_to model_model_file_path(model, file),
        alert: t(".gate_failed", reasons: messages)
      return
    end

    @printer.print_later(file: file)
    redirect_to printer_path(@printer), notice: t(".success", filename: file.filename, printer: @printer.name)
  end

  private

  def load_printer
    @printer = policy_scope(PrintHost).find(params[:id])
  end

  PERMITTED_PRINTER_ATTRS = [
    :name, :endpoint, :mainboard_id, :brand, :machine_model, :firmware, :mac_address,
    :resolution_w, :resolution_h, :build_x_mm, :build_y_mm, :build_z_mm,
    :fep_cycles, :lcd_hours, {native_formats: []}
  ].freeze

  def printer_params
    if params[:printer].present?
      params.expect(printer: PERMITTED_PRINTER_ATTRS)
    else
      params.expect(print_host: PERMITTED_PRINTER_ATTRS)
    end
  end

  def fetch_status(printer)
    fetch_status!(printer)
  rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
    {error: e.message}
  end

  def fetch_status!(printer)
    return {error: "unsupported", unsupported: true} if printer.unsupported_for_send?

    printer.service.normalized_status
  end

  def control_command!(service_method, i18n_key)
    authorize @printer, :control?
    if @printer.unsupported_for_send?
      redirect_to printer_path(@printer), alert: t("printers.send_file.unsupported_printer")
      return
    end

    @printer.service.public_send(service_method)
    redirect_to printer_path(@printer), notice: t("printers.#{i18n_key}.success")
  rescue Print::SdcpService::Error => e
    redirect_to printer_path(@printer), alert: e.message
  end

  def camera_stream_name
    ENV.fetch("GO2RTC_STREAM", "gk3_pro")
  end

  # Static checklist describing gate rules for this host (settings sidebar).
  def build_gate_checklist(printer)
    formats = printer.capability_formats.map { |f| ".#{f}" }.join(", ")
    res = printer.resolution_label || "—"
    z = printer.build_z_mm
    [
      {
        key: :formats,
        pass: formats.present?,
        title: I18n.t("printers.settings.gate.formats_title"),
        detail: I18n.t("printers.settings.gate.formats_detail", formats: formats.presence || "—")
      },
      {
        key: :resolution,
        pass: printer.resolution_w.present? && printer.resolution_h.present?,
        title: I18n.t("printers.settings.gate.resolution_title"),
        detail: I18n.t("printers.settings.gate.resolution_detail", resolution: res)
      },
      {
        key: :z_height,
        pass: z.present?,
        title: I18n.t("printers.settings.gate.z_title"),
        detail: I18n.t("printers.settings.gate.z_detail", z: z.presence || "—")
      },
      {
        key: :aa,
        pass: false,
        title: I18n.t("printers.settings.gate.aa_title"),
        detail: I18n.t("printers.settings.gate.aa_detail")
      }
    ]
  end
end
