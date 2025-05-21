# frozen_string_literal: true

class Components::Link < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(icon:, label:, href:, variant:, method: nil)
    @icon = icon
    @label = label
    @href = href
    @variant = variant
    @method = method
  end

  def view_template
    link_to(@href, method: @method, class: "btn btn-#{@variant}") do
      if @icon
        Icon(icon: @icon, label: @label)
        whitespace
      end
      span { @label }
    end
  end
end
