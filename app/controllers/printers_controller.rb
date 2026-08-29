# frozen_string_literal: true

# First-class Print Studio fleet API (INIT-008/SPEC-004).
# Settings::PrintHosts remains for admin HTML CRUD / camera proxy.
class PrintersController < ApplicationController
  include PrintApi

  respond_to :json

  before_action :load_printer, only: [:show, :update, :status]
  skip_after_action :verify_policy_scoped, only: [:discover]

  def index
    authorize PrintHost
    @printers = policy_scope(PrintHost).order(:name)
    render json: {printers: @printers.map { |host| serialize_printer(host) }}
  end

  def show
    authorize @printer
    status_payload = fetch_status(@printer)
    render json: {printer: serialize_printer(@printer, status: status_payload)}
  end

  def create
    authorize PrintHost
    @printer = PrintHost.new(printer_params)
    @printer.protocol = Print::SdcpService::PROTOCOL
    if @printer.save
      render json: {printer: serialize_printer(@printer)}, status: :created
    else
      render json: {errors: @printer.errors.to_hash}, status: :unprocessable_content
    end
  end

  def update
    authorize @printer
    if @printer.update(printer_params)
      render json: {printer: serialize_printer(@printer)}
    else
      render json: {errors: @printer.errors.to_hash}, status: :unprocessable_content
    end
  end

  # UDP discover — returns candidates only; never persists (REQ-003).
  def discover
    authorize PrintHost, :discover?
    hosts = Array(params[:hosts].presence || ["255.255.255.255"])
    timeout = (params[:timeout].presence || 2.0).to_f
    candidates = Print::SdcpService.discover_candidates(hosts: hosts, timeout: timeout)
    render json: {candidates: candidates}
  end

  def status
    authorize @printer, :show?
    render json: {status: fetch_status!(@printer)}
  rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
    render json: {error: e.message}, status: :bad_gateway
  end

  private

  def load_printer
    @printer = policy_scope(PrintHost).find(params[:id])
  end

  def printer_params
    params.expect(printer: [
      :name, :endpoint, :mainboard_id, :brand, :machine_model, :firmware, :mac_address,
      :resolution_w, :resolution_h, :build_x_mm, :build_y_mm, :build_z_mm,
      :fep_cycles, :lcd_hours, {native_formats: []}
    ])
  end

  def fetch_status(printer)
    fetch_status!(printer)
  rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
    {error: e.message}
  end

  def fetch_status!(printer)
    printer.service.normalized_status
  end
end
