module ModelFilesHelper
  def app_links(file)
    supported_types = {
      bambu: [:threemf],
      # i18n-tasks-use t('model_files.download.bambu')
      # Bambu Studio doesn't seem to open anything except 3MF by URL

      cura: [:threemf, :amf, :collada, :gcode, :gltf, :obj, :ply, :stl, :x3d],
      # i18n-tasks-use t('model_files.download.cura')
      # https://support.makerbot.com/s/article/1667411286871

      elegoo: [:threemf, :amf, :obj, :step, :stl, :svg],
      # i18n-tasks-use t('model_files.download.elegoo')
      # From code at https://github.com/ELEGOO-3D/ElegooSlicer/tree/main/src/libslic3r/Format

      lychee: [:threemf, :lychee, :obj, :stl],
      # i18n-tasks-use t('model_files.download.lychee')
      # https://doc.mango3d.io/doc/filament-documentation/filament-toolbar/import-2/

      orca: [:threemf, :abc, :amf, :obj, :ply, :step, :stl, :svg],
      # i18n-tasks-use t('model_files.download.orca')
      # From file import dialog

      prusa: [],
      # i18n-tasks-use t('model_files.download.prusa')
      # PrusaSlicer only loads from printables.com, so this list is
      # empty until https://github.com/prusa3d/PrusaSlicer/issues/13752 is dealt with.

      superslicer: [:threemf, :amf, :obj, :step, :stl, :svg],
      # i18n-tasks-use t('model_files.download.superslicer')
      # From code at https://github.com/supermerill/SuperSlicer/tree/master_27/src/libslic3r/Format

      freecad: [:threemf, :fcstd, :iges, :obj, :step, :stl]
      # i18n-tasks-use t('model_files.download.freecad')

    }.freeze
    apps = supported_types.filter_map { |app, formats| app if formats.include? file.mime_type.to_sym }
    safe_join(
      apps.map do |app|
        content_tag(:li, role: "presentation") {
          link_to safe_join(
            [
              app_icon_tag(app, alt: t("model_files.download.%{app}" % {app: app})),
              t("model_files.download.%{app}" % {app: app})
            ].compact,
            " "
          ), app_url(app, file), role: "menuitem", class: "dropdown-item", download: "download"
        }
      end
    )
  end

  def app_url(app, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    signed_url = model_model_file_by_signed_filename_url(file.model, file.filename, sig: signed_id)
    case app
    when :orca
      slic3r_family_open_url "orcaslicer", signed_url
    when :prusa, :superslicer
      # Prusa will only open files from printables.com
      slic3r_family_open_url "prusaslicer", signed_url
    when :bambu
      if client_os.family == "Mac OS X"
        URI::Generic.new(
          "bambustudioopen", nil,
          CGI.escapeURIComponent(signed_url), nil, nil, nil, nil,
          nil, nil
        ).to_s
      else
        slic3r_family_open_url "bambustudio", signed_url
      end
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
    when :freecad
      URI::Generic.new(
        "ondsel", nil,
        CGI.escapeURIComponent(signed_url), nil, nil, nil, nil,
        nil, nil
      ).to_s
    end
  end

  def app_icon_tag(app, alt:)
    image_tag("external-icons/#{app}.png", class: "app-icon", alt: alt)
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
