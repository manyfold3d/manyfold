module ApplicationHelper
  def icon(id, label)
    tag.i class: "bi bi-#{id}", role: "img", 'aria-label': label, title: label
  end
end
