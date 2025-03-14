module ModelFilesHelper
  def slicer_url(slicer, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    signed_url = model_url(file.model) + "/model_files/#{signed_id}.#{file.extension}"
    case slicer
    when :orca
      slic3r_family_open_url "orcaslicer", signed_url
    when :prusa
      slic3r_family_open_url "prusaslicer", signed_url
    when :bambu
      slic3r_family_open_url "bambustudioopen", signed_url
    when :cura
      slic3r_family_open_url "cura", signed_url
    end
  end

  private

  def slic3r_family_open_url(scheme, signed_url)
    URI::Generic.new(
      scheme, nil,
      "open", nil, nil, nil, nil,
      {file: signed_url}.to_query, nil
    ).to_s
  end
end
