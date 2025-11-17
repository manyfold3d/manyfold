module ApplicationHelper
  def site_name(default: translate("application.title"))
    SiteSettings.site_name.presence || default
  end

  def site_tagline
    SiteSettings.site_tagline.presence || t("application.tagline")
  end

  def site_icon
    SiteSettings.site_icon.presence || "roundel.svg"
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

  def markdownify(text)
    Kramdown::Document.new(
      sanitize(text),
      header_offset: 2,
      input: "GFM"
    ).to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def card(style, title = nil, options = {}, &content)
    id = options[:id] || "card-#{SecureRandom.hex(4)}"
    card_class = ["card", "mb-4", options[:class]].join(" ")
    if options[:skip_link]
      skiplink = skip_link(options[:skip_link][:target], options[:skip_link][:text])
      card_class += " skip-link-container"
    end
    tag.div class: card_class, data: options[:data], id: id do
      safe_join([
        if title.present?
          tag.div(class: "card-header text-white bg-#{style}") do
            options[:collapse] ?
              safe_join([
                title,
                tag.span(Icon(icon: "arrows-expand", label: t("general.expand")), class: "float-end d-#{options[:collapse]}-none"),
                tag.a(
                  nil,
                  class: "link-unstyled stretched-link d-#{options[:collapse]}-none",
                  "data-bs-toggle": "collapse",
                  "data-bs-target": "##{id}-collapse",
                  "aria-expanded": false,
                  "aria-controls": "#{id}-collapse"
                )
              ]) :
              title
          end
        end,
        skiplink,
        tag.div(class: "card-body #{"collapse d-#{options[:collapse]}-block" if options[:collapse]}", id: "#{id}-collapse") do
          tag.div class: "card-text" do
            yield
          end
        end
      ].compact)
    end
  end

  def text_input_row(form, attribute, options = {})
    TextInputRow(
      form: form,
      attribute: attribute,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def password_input_row(form, attribute, options = {})
    PasswordInputRow(
      form: form,
      attribute: attribute,
      strength_meter: options.delete(:strength_meter),
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def url_input_row(form, attribute, options = {})
    UrlInputRow(
      form: form,
      attribute: attribute,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def numeric_input_row(form, attribute, options = {})
    NumericInputRow(
      form: form,
      attribute: attribute,
      unit: options.delete(:unit),
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def rich_text_input_row(form, attribute, options = {})
    RichTextInputRow(
      form: form,
      attribute: attribute,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def checkbox_input_row(form, attribute, options = {})
    CheckBoxInputRow(
      form: form,
      attribute: attribute,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def select_input_row(form, attribute, select_options, options = {})
    SelectInputRow(
      form: form,
      attribute: attribute,
      select_options: select_options,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def collection_select_input_row(form, attribute, collection, value_method, text_method, options = {})
    CollectionSelectInputRow(
      form: form,
      attribute: attribute,
      collection: collection,
      value_method: value_method,
      text_method: text_method,
      label: options.delete(:label),
      help: options.delete(:help),
      options: options
    )
  end

  def file_input_row(form, name, options = {})
    safe_join([
      content_tag(:div) do
        form.label(name, options[:label], class: "col-form-label")
      end,
      content_tag(:div) do
        safe_join [
          content_tag(:div, class: "input-group") do
            safe_join [
              form.file_field(name, class: "form-control"),
              options[:remove] ? form.check_box(:"remove_#{name}", class: "btn-check", autocomplete: "off") : nil,
              options[:remove] ? form.label(:"remove_#{name}", Icon(icon: "trash", label: options[:remove_label]), class: "btn btn-outline-danger") : nil
            ].compact
          end,
          errors_for(form.object, name),
          (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
        ].compact
      end
    ])
  end

  def nav_link(ico, text, path, options = {})
    link_to(
      safe_join(
        [
          content_tag(:span, Icon(icon: ico, label: options[:title].presence || text), class: options[:icon_style]),
          content_tag(:span, text, class: options[:text_style])
        ],
        " "
      ),
      path,
      class: options[:style] || safe_join(["nav-link", (current_page?(path) ? "active" : "")], " "),
      method: options[:method],
      rel: options[:nofollow] ? "nofollow" : nil,
      id: options[:id],
      data: options[:data],
      aria: {
        label: options[:aria_label]
      }
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
      link_to text, "##{target}", class: "text-reset", tabindex: 0
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

  def random_password
    (SecureRandom.base64(32) + "!0aB").chars.shuffle.join
  end

  def server_indicator(object, full_address: false)
    actor = object.respond_to?(:federails_actor) ? object.federails_actor : object
    return if !SiteSettings.federation_enabled? || actor.local?
    link_to actor.profile_url, class: "link-primary link-underline-opacity-0 link-underline-opacity-100-hover" do
      safe_join([
        "⁂",
        full_address ? actor.at_address : actor.server
      ], " ")
    end
  end

  def oembed_params
    params.permit(:maxwidth, :maxheight)
  end

  def indexable_select_options(object)
    current = object.inherited_indexable? ? translate("application_helper.indexable_select_options.yes") : translate("application_helper.indexable_select_options.no")
    options_for_select(
      [
        [translate("application_helper.indexable_select_options.inherit", inherited: current), "inherit"],
        [translate("application_helper.indexable_select_options.always_no"), "no"],
        [translate("application_helper.indexable_select_options.always_yes"), "yes"]
      ],
      selected: object&.indexable || "inherit"
    )
  end

  def ai_indexable_select_options(object)
    current = object.inherited_ai_indexable? ? translate("application_helper.indexable_select_options.yes") : translate("application_helper.indexable_select_options.no")
    options_for_select(
      [
        [translate("application_helper.ai_indexable_select_options.inherit", inherited: current), "inherit"],
        [translate("application_helper.ai_indexable_select_options.always_no"), "no"],
        [translate("application_helper.ai_indexable_select_options.always_yes"), "yes"]
      ],
      selected: object&.ai_indexable || "inherit"
    )
  end

  def tour_attributes(id:, title:, description:)
    return {} if current_user.nil? || current_user.first_use?
    {
      "tour-id": id,
      "tour-id-completed": current_user.tour_state.dig("completed").include?(id).to_s,
      "tour-title": title,
      "tour-description": description
    }
  end
end
