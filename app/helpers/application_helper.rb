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
            content.call
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

  def params_passthrough
    params.permit!.slice(:library, :collection, :tag, :q, :creator)
  end
end
