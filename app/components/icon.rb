# frozen_string_literal: true

class Components::Icon < Components::Base
  def initialize(icon:, id: nil, label: nil, effect: nil, role: "img")
    @icon = icon
    @effect = effect
    @id = id
    @label = label
    @role = role
  end

  def before_template
    prefix = "bi"
    icon = @icon
    if icon.starts_with? "ra-"
      prefix = "ra"
      icon = @icon.gsub("ra-", "")
    end
    @classes = [prefix, "#{prefix}-#{icon}", @effect].compact.join(" ")
  end

  def view_template
    i class: @classes, role: @role, title: @label, id: @id
  end
end
