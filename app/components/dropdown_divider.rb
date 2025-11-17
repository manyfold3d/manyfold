# frozen_string_literal: true

class Components::DropdownDivider < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize
  end

  def view_template
    li(role: "presentation") { hr class: "dropdown-divider" }
  end
end
