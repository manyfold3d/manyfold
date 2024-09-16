module ApplicationHelper
  def icon(icon, label, id: nil)
    prefix = "bi"
    if icon.starts_with? "ra-"
      prefix = "ra"
      icon = icon.gsub("ra-", "")
    end
    tag.i class: "#{prefix} #{prefix}-#{icon}", role: "img", title: label, id: id
  end

  def icon_for(klass)
    case klass.name
    when "Creator"
      "person"
    when "Collection"
      "collection"
    when "Library"
      "boxes"
    when "Model"
      "box"
    when "ModelFile"
      "file"
    when "User"
      "person"
    end
  end

  def card(style, title, options = {}, &content)
    id = "card-#{SecureRandom.hex(4)}"
    card_class = "card mb-4"
    if options[:skip_link]
      skiplink = skip_link(options[:skip_link][:target], options[:skip_link][:text])
      card_class += " skip-link-container"
    end
    tag.div class: card_class do
      safe_join([
        tag.div(class: "card-header text-white bg-#{style}") do
          options[:collapse] ?
            safe_join([
              title,
              tag.span(icon("arrows-expand", t("general.expand")), class: "float-end d-#{options[:collapse]}-none"),
              tag.a(
                nil,
                class: "link-unstyled stretched-link d-#{options[:collapse]}-none",
                "data-bs-toggle": "collapse",
                "data-bs-target": "##{id}",
                "aria-expanded": false,
                "aria-controls": id
              )
            ]) :
            title
        end,
        skiplink,
        tag.div(class: "card-body #{"collapse d-#{options[:collapse]}-block" if options[:collapse]}", id: id) do
          tag.div class: "card-text" do
            yield
          end
        end
      ].compact)
    end
  end

  def renderable?(format)
    case format
    when "stl", "obj", "3mf", "ply", "gltf", "glb"
      true
    else
      false
    end
  end

  def text_input_row(form, name, options = {})
    safe_join [
      form.label(name, class: "col-form-label "),
      content_tag(:div) do
        safe_join [
          form.text_field(name, {class: "form-control"}.merge(options)),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ]
  end

  def password_input_row(form, name, options = {})
    safe_join [
      form.label(name, class: "col-form-label "),
      content_tag(:div) do
        safe_join [
          form.password_field(name, {class: "form-control"}.merge(options)),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ]
  end

  def rich_text_input_row(form, name, options = {})
    safe_join [
      form.label(name, class: "col-form-label "),
      content_tag(:div) do
        safe_join [
          form.text_area(name, class: "form-control"),
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ]
  end

  def nav_link(ico, text, path, options = {})
    link_to(
      safe_join(
        [
          content_tag(:span, icon(ico, (options[:title].presence || text)), class: options[:icon_style]),
          content_tag(:span, text, class: options[:text_style])
        ],
        " "
      ),
      path,
      class: options[:style] || safe_join(["nav-link", (current_page?(path) ? "active" : "")], " "),
      method: options[:method],
      "aria-label": options[:aria_label]
    )
  end

  def errors_for(record, attribute)
    return if record.nil? || attribute.nil?
    return unless record.errors.include? attribute
    content_tag(:div,
      record.errors.full_messages_for(attribute).join("; "),
      class: "invalid-feedback d-block")
  end

  def skip_link(target, text)
    content_tag :div, class: "container-fluid skip-link text-bg-success p-2" do
      link_to text, "##{target}", class: "text-reset"
    end
  end

  def translate_with_locale_wrapper(key, **options)
    translate(key, **options) do |str, _key|
      str&.locale ? content_tag(:span, lang: str.locale) { sanitize str } : str
    end
  end
  alias_method :t, :translate_with_locale_wrapper

  def pagination_settings
    current_user&.pagination_settings || SiteSettings::UserDefaults::PAGINATION
  end

  def tag_cloud_settings
    current_user&.tag_cloud_settings || SiteSettings::UserDefaults::TAG_CLOUD.merge(heatmap: false)
  end

  def renderer_settings
    current_user&.renderer_settings || SiteSettings::UserDefaults::RENDERER
  end

  def file_list_settings
    current_user&.file_list_settings || SiteSettings::UserDefaults::FILE_LIST
  end

  def problem_settings
    current_user&.problem_settings || Problem::DEFAULT_SEVERITIES
  end
end
