# frozen_string_literal: true

class Components::Button < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(icon:, text:, href:, variant:, method: nil)
    @icon = icon
    @text = text
    @href = href
    @variant = variant
    @method = method
  end

  def view_template
    button_to(@href, method: @method, class: "btn btn-#{@variant}") do
      if @icon
        Icon(icon: @icon, label: @text)
        whitespace
      end
      span { @text }
    end
  end
end
