module ModelFilesHelper
  def app_links(file)
    handlers = FileHandlers::Base.handlers_for(environment: :client, load_file: file)
    safe_join(
      handlers.map do |handler|
        name = handler.name.demodulize.underscore
        content_tag(:li, role: "presentation") {
          link_to safe_join(
            [
              app_icon_tag(name, alt: t("model_files.download.%{name}" % {name: name})),
              t("model_files.download.%{name}" % {name: name})
            ].compact,
            " "
          ), app_url(handler, file), role: "menuitem", class: "dropdown-item", download: "download"
        }
      end
    )
  end

  def app_url(handler, file)
    signed_id = file.signed_id expires_in: 1.hour, purpose: "download"
    signed_url = model_model_file_by_signed_filename_url(file.model, file.filename, sig: signed_id)
    handler.open_url_for(signed_url, client_os: UserAgentParser.parse(request&.user_agent)&.os)
  end

  def app_icon_tag(app, alt:)
    image_tag("external-icons/#{app}.png", class: "app-icon", alt: alt)
  end
end
