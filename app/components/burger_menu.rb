# frozen_string_literal: true

class Components::BurgerMenu < Components::Base
  def initialize(small: false, id: SecureRandom.uuid, data: {})
    @small = small
    @id = id
    @data = data
  end

  def view_template
    classes = %w[btn btn-secondary]
    classes << "btn-sm" if @small
    div data: @data do
      a id: @id,
        href: "#",
        data: {
          bs_toggle: "dropdown"
        },
        aria: {
          expanded: false,
          haspopup: true,
          controls: "menu"
        },
        class: classes.join(" "),
        tabindex: 0 do
        Icon icon: "list", label: t("general.menu")
      end
      ul class: "dropdown-menu dropdown-menu-end",
        role: "menu",
        aria: {labelledby: @id} do
        yield
      end
    end
  end
end
