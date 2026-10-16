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
    iframe id: "kiri-moto", class: "slicer", src: "https://grid.space/kiri", data: {controller: "kiri-moto", kiri_moto_url_value: @url}
  end
end
