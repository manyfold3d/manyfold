module ModelFilesHelper
  prepend MemoWise

  def can_print?(file)
    policy(file).print? && print_hosts_for(file.mime_type).any?
  end

  def print_hosts_for(mime_type)
    policy_scope(PrintHost).all.select { mime_type.in? it.input_types }
  end
  memo_wise :print_hosts_for

  def print_links(file)
    safe_join(
      print_hosts_for(file.mime_type).map do |print_host|
        content_tag(:li, role: "presentation") {
          link_to safe_join(
            [
              Icon(icon: "printer", role: "presentation"),
              t("model_files.print.link", print_host_name: print_host.name)
            ], " "
          ),
            print_print_host_path(print_host, file_id: file.public_id),
            method: "post",
            role: "menuitem",
            class: "dropdown-item",
            data: {
              confirm: translate("model_files.print.confirm")
            }
        }
      end
    )
  end

  def app_links(file)
    handlers = FileHandlers.handlers_for(environment: :client, mime_type: file.mime_type)
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
    handler.open_url_for(signed_url, client_os: -> { client_os })
  end

  def app_icon_tag(app, alt:)
    vite_image_tag("images/external-icons/#{app}.png", class: "app-icon", alt: alt)
  end

  def tab_title(file)
    [
      file.extension.upcase,
      (file.presupported ? t("activerecord.attributes.model_file.presupported") : nil)
    ].compact_blank.join(", ")
  end
end
