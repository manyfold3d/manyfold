# frozen_string_literal: true

class Components::BurgerMenu < Components::Base
  def view_template
    div class: "btn-group" do
      a href: "#", role: "button", data: {bs_toggle: "dropdown"}, aria: {expanded: false} do
        Icon icon: "three-dots-vertical", label: t("general.menu")
      end
      ul class: "dropdown-menu dropdown-menu-end" do
        yield
      end
    end
  end
end
