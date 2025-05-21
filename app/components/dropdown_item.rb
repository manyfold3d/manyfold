# frozen_string_literal: true

class Components::DropdownItem < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(icon:, label:, path:, method: nil)
    @icon = icon
    @label = label
    @path = path
    @method = method
  end

  def view_template
    li do
      link_to @path, method: @method, class: "dropdown-item" do
        Icon(icon: @icon, label: @label)
        whitespace
        span { @label }
      end
    end
  end
end
