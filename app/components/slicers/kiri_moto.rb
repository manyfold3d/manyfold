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
        action: "message@window->kiri-moto#onMessage"
      }
    ) do
      iframe(
        id: "kiri-moto-frame",
        class: "slicer",
        src: "https://floppy2.ngrok.pizza/kiri",
        data: {
          action: "load->kiri-moto#onFrameLoaded",
          kiri_moto_target: "iframe"
        }
      )
      button(
        class: "btn btn-primary",
        data: {
          action: "click->kiri-moto#export:prevent"
        }
      ) { "Save sliced file" }
    end
  end
end
