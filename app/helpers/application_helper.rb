module ApplicationHelper
  def icon(id, label)
    tag.i class: "bi bi-#{id}", role: "img", "aria-label": label, title: label
  end

  def card(style, title, &content)
    tag.div class: "card mb-4" do
      [
        tag.div(title, class: "card-header text-white bg-#{style}"),
        tag.div(class: "card-body") do
          tag.div class: "card-text" do
            yield
          end
        end
      ].join.html_safe
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
      "bg-secondary link-light"
    end
  end

  def text_input_row(form, name)
    content_tag :div, class: "row mb-3 input-group" do
      [
        form.label(name, class: "col-sm-2 col-form-label"),
        form.text_field(name, class: "form-control col-auto")
      ].join.html_safe
    end
  end

  def rich_text_input_row(form, name)
    content_tag :div, class: "row mb-3 input-group" do
      [
        form.label(name, class: "col-sm-2 col-form-label"),
        form.text_area(name, class: "form-control col-auto")
      ].join.html_safe
    end
  end
end
