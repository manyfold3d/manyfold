# frozen_string_literal: true

module ModelFiles
  # Gated send eligibility for a ModelFile against a PrintHost (REQ-004).
  # STL / non-sliced formats are never offered.
  class SendEligibilitiesController < ApplicationController
    include PrintApi

    respond_to :json

    before_action :load_model_and_file
    skip_after_action :verify_policy_scoped

    def show
      authorize @file, :show?
      print_host = policy_scope(PrintHost).find(params.require(:print_host_id))
      authorize print_host, :control?

      extension = @file.extension.to_s.downcase
      unless @file.sliced_for_print?
        render json: {
          eligible: false,
          offered: false,
          reasons: [{
            code: "format_not_sliced",
            message: "Only CTB/JXS sliced files may be sent; STL and meshes are not offered",
            expected: ModelFile::SLICED_PRINT_EXTENSIONS,
            actual: extension.presence || "unknown"
          }]
        }
        return
      end

      if print_host.unsupported_for_send?
        render json: {
          eligible: false,
          offered: false,
          reasons: [{
            code: "printer_unsupported",
            message: "This printer family is not supported for send in Print Studio",
            expected: Print::SdcpService::PROTOCOL,
            actual: print_host.protocol
          }]
        }
        return
      end

      stamp = {
        format: extension,
        resolution_w: params[:resolution_w],
        resolution_h: params[:resolution_h],
        z_height_mm: params[:z_height_mm],
        aa: params[:aa]
      }.compact
      result = Print::CompatibilityGate.call(print_host: print_host, stamp: stamp)

      render json: {
        eligible: result.pass?,
        offered: result.pass?,
        reasons: serialize_gate_reasons(result.reasons),
        print_host_id: print_host.id,
        model_file_id: @file.to_param,
        format: extension
      }
    end

    private

    def load_model_and_file
      @model = policy_scope(Model).find_param(params[:model_id])
      @file = policy_scope(@model.model_files).find_param(params[:id])
    end
  end
end
