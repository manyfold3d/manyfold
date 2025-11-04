# frozen_string_literal: true

class Components::BurgerMenu < Components::Base
  def initialize(small: false, id: nil, data: {})
    @small = small
    @id = id
    @data = data
  end

  def view_template
    classes = %w[btn btn-secondary]
    classes << "btn-sm" if @small
    div id: @id, data: @data do
      a href: "#", role: "button", data: {bs_toggle: "dropdown"}, aria: {expanded: false}, class: classes.join(" ") do
        Icon icon: "list", label: t("general.menu")
      end
      ul class: "dropdown-menu dropdown-menu-end" do
        yield
      end
    end
  end
end
