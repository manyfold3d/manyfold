# frozen_string_literal: true

class Components::Slicers::KiriMoto < Components::Base
  def initialize(file:)
    @file = file
  end

  def before_template
    signed_id = @file.signed_id expires_in: 1.hour, purpose: "download"
    @url = Rails.application.routes.url_helpers.model_model_file_by_signed_filename_url(@file.model, @file.filename, sig: signed_id)
  end

  def view_template
    div(
      data: {
        controller: "kiri-moto",
        kiri_moto_origin_value: root_url,
        kiri_moto_url_value: @url,
        kiri_moto_upload_url_value: upload_url,
        kiri_moto_model_url_value: url_for(@file.model),
        kiri_moto_source_file_id_value: @file.public_id,
        action: "message@window->kiri-moto#onMessage"
      }
    ) do
      iframe(
        id: "kiri-moto-frame",
        class: "slicer",
        src: "/applications/kiri",
        data: {
          kiri_moto_target: "iframe"
        }
      )
      div class: "form-save-button row justify-content-end" do
        label(class: "col-auto col-form-label") { translate("components.kiri_moto.filename") + ":" }
        div class: "col-auto" do
          div class: "input-group" do
            input(
              type: "text",
              class: "border-primary form-control",
              value: @file.basename,
              data: {kiri_moto_target: "basename"}
            )
            span(
              class: "input-group-text border-primary",
              data: {kiri_moto_target: "extension"}
            ) { ".gcode" }
          end
        end
        div class: "col-auto" do
          button(
            disabled: true,
            data: {
              action: "click->kiri-moto#export:prevent",
              kiri_moto_target: "saveButton"
            }
          ) { translate("components.kiri_moto.save") }
        end
      end
    end
  end
end
