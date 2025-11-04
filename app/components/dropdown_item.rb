# frozen_string_literal: true

class Components::DropdownItem < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(label:, path:, icon: nil, method: nil, aria_label: nil, confirm: nil, nofollow: nil)
    @icon = icon
    @label = label
    @path = path
    @method = method
    @aria_label = aria_label
    @confirm = confirm
    @nofollow = nofollow
  end

  def view_template
    li do
      link_to @path, method: @method, class: "dropdown-item", aria: {label: @aria_label}, data: {confirm: @confirm}, nofollow: @nofollow do
        if @icon
          Icon(icon: @icon, label: @label)
          whitespace
        end
        span { @label }
      end
    end
  end
end
