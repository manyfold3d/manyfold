# frozen_string_literal: true

class Components::BurgerMenu < Components::Base
  def initialize(small: false, direction: :down, id: SecureRandom.uuid, data: {})
    @small = small
    @id = id
    @data = data
    @direction = direction
  end

  def view_template
    classes = %w[btn btn-secondary]
    classes << "btn-sm" if @small
    div data: @data, class: ("dropup" if @direction == :up) do
      a id: @id,
        href: "#",
        data: {
          bs_toggle: "dropdown"
        },
        aria: {
          expanded: false,
          haspopup: "menu",
          controls: "#{@id}-menu"
        },
        class: classes.join(" "),
        tabindex: 0 do
        Icon icon: "list", label: t("general.menu")
      end
      ul class: "dropdown-menu dropdown-menu-end",
        id: "#{@id}-menu",
        role: "menu",
        aria: {labelledby: @id} do
        yield
      end
    end
  end
end
