module ModelFilesHelper
  def slicer_url(slicer, file)
    case slicer
    when :orca
      slic3r_family_open_url "orcaslicer", file
    when :prusa
      slic3r_family_open_url "prusaslicer", file
    when :bambu
      slic3r_family_open_url "bambustudio", file
    when :cura
      slic3r_family_open_url "cura", file
    end
  end

  private

  def slic3r_family_open_url(scheme, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    url = model_url(file.model) + "/model_files/#{signed_id}.#{file.extension}"
    URI::Generic.new(
      scheme, nil,
      "open", nil, nil, nil, nil,
      {file: url}.to_query, nil
    ).to_s
  end
end
