# frozen_string_literal: true

module Printers
  # On-printer storage list / upload / delete (REQ-005).
  class StorageFilesController < ApplicationController
    include PrintApi

    respond_to :html, :json

    before_action :load_printer
    skip_after_action :verify_policy_scoped

    def index
      authorize @printer, :storage?
      files = @printer.service.list_files(url: params[:url].presence || "/local")
      free = @printer.service.storage_free_bytes
      render json: {
        files: files,
        storage_bytes_used: @printer.storage_bytes_used,
        storage_bytes_total: @printer.storage_bytes_total,
        storage_bytes_free: free
      }
    rescue Print::SdcpService::Error, *Print::SdcpService::TRANSPORT_ERRORS => e
      render json: {error: e.message}, status: :bad_gateway
    end

    def create
      authorize @printer, :storage?
      uploaded = params[:file] || params.dig(:storage_file, :file)
      if uploaded.blank?
        respond_to do |format|
          format.json { render json: {error: "missing_file"}, status: :unprocessable_content }
          format.html { redirect_to settings_printer_path(@printer), alert: t("printers.storage.missing_file") }
        end
        return
      end

      filename = if uploaded.respond_to?(:original_filename)
        uploaded.original_filename.to_s
      else
        File.basename(uploaded.path.to_s)
      end
      extension = File.extname(filename).delete(".").downcase
      unless %w[ctb jxs].include?(extension)
        respond_to do |format|
          format.json {
            render json: {
              error: "unsupported_file_type",
              message: "STL and other mesh formats are not offered for printer upload",
              reasons: [{
                code: "format_unsupported",
                message: "Only CTB/JXS sliced files may be uploaded",
                expected: %w[ctb jxs],
                actual: extension.presence || "unknown"
              }]
            }, status: :unprocessable_content
          }
          format.html { redirect_to settings_printer_path(@printer), alert: t("printers.storage.unsupported_type") }
        end
        return
      end

      io = uploaded.respond_to?(:tempfile) ? uploaded.tempfile : uploaded
      result = @printer.service.upload(
        io: io,
        filename: filename,
        content_type: (uploaded.content_type if uploaded.respond_to?(:content_type)),
        start: false
      )
      respond_to do |format|
        format.json { render json: {upload: result}, status: :created }
        format.html { redirect_to settings_printer_path(@printer), notice: t("printers.storage.uploaded", filename: filename) }
      end
    rescue Print::SdcpService::UnsupportedFileType
      respond_to do |format|
        format.json {
          render json: {
            error: "unsupported_file_type",
            message: "STL and other mesh formats are not offered for printer upload",
            reasons: [{code: "format_unsupported", message: "Only CTB/JXS sliced files may be uploaded"}]
          }, status: :unprocessable_content
        }
        format.html { redirect_to settings_printer_path(@printer), alert: t("printers.storage.unsupported_type") }
      end
    rescue Print::SdcpService::Error => e
      respond_to do |format|
        format.json { render json: {error: e.message}, status: :unprocessable_content }
        format.html { redirect_to settings_printer_path(@printer), alert: e.message }
      end
    end

    def destroy
      authorize @printer, :storage?
      file_list = Array(params[:file_list] || params.dig(:storage_file, :file_list))
      folder_list = Array(params[:folder_list] || params.dig(:storage_file, :folder_list))
      if file_list.blank? && folder_list.blank?
        respond_to do |format|
          format.json { render json: {error: "nothing_to_delete"}, status: :unprocessable_content }
          format.html { redirect_to settings_printer_path(@printer), alert: t("printers.storage.nothing_to_delete") }
        end
        return
      end

      @printer.service.delete_files(file_list: file_list, folder_list: folder_list)
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to settings_printer_path(@printer), notice: t("printers.storage.deleted") }
      end
    rescue Print::SdcpService::Error => e
      respond_to do |format|
        format.json { render json: {error: e.message}, status: :unprocessable_content }
        format.html { redirect_to settings_printer_path(@printer), alert: e.message }
      end
    end

    private

    def load_printer
      # Authorize class first so non-admins get 403 (not 404 from empty scope).
      authorize PrintHost, :storage?
      @printer = policy_scope(PrintHost).find(params[:printer_id])
    end
  end
end
