# frozen_string_literal: true

class Components::DropdownItem < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(label:, path:, icon: nil, method: nil, aria_label: nil, confirm: nil, active: false)
    @icon = icon
    @label = label
    @path = path
    @method = method
    @aria_label = aria_label
    @confirm = confirm
    @active = active
  end

  def view_template
    li do
      link_to @path, method: @method, class: "dropdown-item #{"active" if @active}", aria: {label: @aria_label, current: @active.to_s}, data: {confirm: @confirm}, rel: "nofollow" do
        if @icon
          Icon(icon: @icon, label: @label)
          whitespace
        end
        span { @label }
      end
    end
  end
end
