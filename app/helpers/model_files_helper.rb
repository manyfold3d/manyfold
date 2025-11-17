module ModelFilesHelper
  def slicer_links(file)
    # i18n-tasks-use t('model_files.download.cura')
    # i18n-tasks-use t('model_files.download.orca')
    # i18n-tasks-use t('model_files.download.prusa')
    # i18n-tasks-use t('model_files.download.bambu')
    # i18n-tasks-use t('model_files.download.elegoo')
    # i18n-tasks-use t('model_files.download.superslicer')
    # i18n-tasks-use t('model_files.download.lychee')
    safe_join(
      [:cura, :orca, :elegoo, :superslicer, :lychee].map do |slicer|
        content_tag(:li, role: "presentation") {
          link_to safe_join(
            [
              slicer_icon_tag(slicer, alt: t("model_files.download.%{slicer}" % {slicer: slicer})),
              t("model_files.download.%{slicer}" % {slicer: slicer})
            ].compact,
            " "
          ), slicer_url(slicer, file), role: "menuitem", class: "dropdown-item", download: "download"
        }
      end
    )
  end

  def slicer_url(slicer, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    signed_url = model_model_file_by_signed_filename_url(file.model, file.filename, sig: signed_id)
    case slicer
    when :orca
      slic3r_family_open_url "orcaslicer", signed_url
    when :prusa, :superslicer
      # Prusa will only open files from printables.com
      slic3r_family_open_url "prusaslicer", signed_url
    when :bambu
      # Bambu will only open from Makerworld and a few others
      slic3r_family_open_url "bambustudioopen", signed_url
    when :cura
      slic3r_family_open_url "cura", signed_url
    when :elegoo
      slic3r_family_open_url "elegooslicer", signed_url
    when :lychee
      URI::Generic.new(
        "lycheeslicer", nil,
        "open", nil, nil, CGI.escapeURIComponent(signed_url), nil,
        nil, nil
      ).to_s
    end
  end

  def slicer_icon_tag(slicer, alt:)
    url = case slicer
    when :orca
      "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/orcaslicer.webp"
    when :cura
      "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/cura.webp"
    when :elegoo
      "https://raw.githubusercontent.com/ELEGOO-3D/ElegooSlicer/refs/heads/main/resources/images/ElegooSlicer.svg"
    when :superslicer
      "https://raw.githubusercontent.com/supermerill/SuperSlicer/refs/heads/master_27/resources/icons/SuperSlicer.svg"
    when :lychee
      "https://lychee.co/static/metas/favicon-32x32.png"
    end
    return if url.nil?
    image_tag(url, class: "slicer-icon", alt: alt)
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
