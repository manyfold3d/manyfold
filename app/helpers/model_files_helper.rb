module ModelFilesHelper
  def slicer_links(file)
    # i18n-tasks-use t('model_files.download.cura')
    # i18n-tasks-use t('model_files.download.orca')
    # i18n-tasks-use t('model_files.download.prusa')
    # i18n-tasks-use t('model_files.download.bambu')
    safe_join(
      [:cura, :orca].map do |slicer|
        content_tag(:li) { link_to t("model_files.download.%{slicer}" % {slicer: slicer}), slicer_url(slicer, file), class: "dropdown-item", download: "download" }
      end
    )
  end

  def slicer_url(slicer, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    signed_url = model_url(file.model) + "/model_files/#{signed_id}.#{file.extension}"
    case slicer
    when :orca
      slic3r_family_open_url "orcaslicer", signed_url
    when :prusa
      # Prusa will only open files from printables.com
      slic3r_family_open_url "prusaslicer", signed_url
    when :bambu
      # Bambu will only open from Makerworld and a few others
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
