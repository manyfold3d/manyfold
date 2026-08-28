# frozen_string_literal: true

module Settings
  class PrintHostsController < ApplicationController
    respond_to :html

    before_action :load_print_host, only: [
      :show, :edit, :update, :destroy,
      :pause, :stop, :continue, :status, :snapshot, :upload_slice
    ]

    def index
      @print_hosts = policy_scope(PrintHost).order(:name)
      render layout: "settings"
    end

    def show
      authorize @print_host
      @status = begin
        @print_host.service.status
      rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
        {error: e.message}
      end
      render layout: "settings"
    end

    def new
      authorize PrintHost
      @print_host = PrintHost.new(protocol: Print::SdcpService::PROTOCOL)
      render layout: "settings"
    end

    def create
      authorize PrintHost
      @print_host = PrintHost.new(print_host_params)
      @print_host.protocol = Print::SdcpService::PROTOCOL
      if @print_host.save
        redirect_to settings_print_host_path(@print_host), notice: t(".success")
      else
        render :new, layout: "settings", status: :unprocessable_content
      end
    end

    def edit
      authorize @print_host
      render layout: "settings"
    end

    def update
      authorize @print_host
      if @print_host.update(print_host_params)
        redirect_to settings_print_host_path(@print_host), notice: t(".success")
      else
        render :edit, layout: "settings", status: :unprocessable_content
      end
    end

    def destroy
      authorize @print_host
      @print_host.destroy!
      redirect_to settings_print_hosts_path, notice: t(".success")
    end

    def pause
      control!("pause") { @print_host.service.pause_print }
    end

    def stop
      control!("stop") { @print_host.service.stop_print }
    end

    def continue
      control!("continue") { @print_host.service.continue_print }
    end

    def status
      authorize @print_host, :show?
      payload = @print_host.service.status
      render json: payload
    rescue Print::SdcpService::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      render json: {error: e.message}, status: :bad_gateway
    end

    # Authenticated JPEG proxy — browsers never talk to go2rtc ClusterIP directly.
    def snapshot
      authorize @print_host, :show?
      jpeg = Print::Go2rtcClient.frame_jpeg(stream: camera_stream_name)
      send_data jpeg, type: "image/jpeg", disposition: "inline"
    rescue Print::Go2rtcClient::Error => e
      Rails.logger.warn("[PrintHosts#snapshot] #{e.class}: #{e.message}")
      head :bad_gateway
    end

    def upload_slice
      authorize @print_host, :control?
      uploaded = params.dig(:print, :file)
      if uploaded.blank?
        redirect_to settings_print_host_path(@print_host), alert: t(".missing_file")
        return
      end

      filename = uploaded.original_filename.to_s
      begin
        @print_host.service.upload(
          io: uploaded.tempfile,
          filename: filename,
          content_type: uploaded.content_type,
          start: ActiveModel::Type::Boolean.new.cast(params.dig(:print, :start)) != false
        )
        redirect_to settings_print_host_path(@print_host), notice: t(".success", filename: filename)
      rescue Print::SdcpService::UnsupportedFileType
        redirect_to settings_print_host_path(@print_host), alert: t(".unsupported_type")
      rescue Print::SdcpService::Error => e
        redirect_to settings_print_host_path(@print_host), alert: e.message
      end
    end

    private

    def load_print_host
      @print_host = policy_scope(PrintHost).find(params[:id])
    end

    def print_host_params
      params.expect(print_host: [:name, :endpoint, :mainboard_id])
    end

    def control!(action)
      authorize @print_host, :control?
      yield
      redirect_to settings_print_host_path(@print_host), notice: t("settings.print_hosts.#{action}.success")
    rescue Print::SdcpService::Error => e
      redirect_to settings_print_host_path(@print_host), alert: e.message
    end

    def camera_stream_name
      ENV.fetch("GO2RTC_STREAM", "gk3_pro")
    end
  end
end
