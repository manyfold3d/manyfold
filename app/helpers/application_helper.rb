module ApplicationHelper
  def icon(id, label)
    tag.i class: "bi bi-#{id}", role: "img", title: label
  end

  def card(style, title, options = {}, &content)
    id = "card-#{SecureRandom.hex(4)}"
    tag.div class: "card mb-4" do
      safe_join [
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
        tag.div(class: "card-body #{"collapse d-#{options[:collapse]}-block" if options[:collapse]}", id: id) do
          tag.div class: "card-text" do
            yield
          end
        end
      ]
    end
  end

  def renderable?(format)
    case format
    when "stl", "obj", "3mf", "ply"
      true
    else
      false
    end
  end

  def tag_class(state)
    case state
    when :highlight
      "bg-primary"
    when :mute
      "border border-muted text-muted pe-none"
    when :hide
      "d-none"
    else
      "bg-secondary"
    end
  end

  def text_input_row(form, name, options = {})
    content_tag :div, class: "row mb-3 input-group" do
      safe_join [
        form.label(name, class: "col-auto col-form-label"),
        content_tag(:div, class: "col p-0") do
          safe_join [
            form.text_field(name, {class: "form-control"}.merge(options)),
            errors_for(form.object, name),
            (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
          ].compact
        end
      ]
    end
  end

  def password_input_row(form, name, options = {})
    content_tag :div, class: "row mb-3 input-group" do
      safe_join [
        form.label(name, class: "col-auto col-form-label"),
        content_tag(:div, class: "col p-0") do
          safe_join [
            form.password_field(name, {class: "form-control"}.merge(options)),
            errors_for(form.object, name),
            (options[:help] ? content_tag(:span, class: "form-text") { options[:help] } : nil)
          ].compact
        end
      ]
    end
  end

  def rich_text_input_row(form, name)
    content_tag :div, class: "row mb-3 input-group" do
      safe_join [
        form.label(name, class: "col-auto col-form-label"),
        form.text_area(name, class: "form-control col-auto")
      ]
    end
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
      method: options[:method]
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
end
