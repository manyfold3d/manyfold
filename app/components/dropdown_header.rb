# frozen_string_literal: true

class Components::DropdownHeader < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(text:)
    @text = text
  end

  def view_template
    li role: "presentation" do
      h6(class: "dropdown-header") { @text }
    end
  end
end
