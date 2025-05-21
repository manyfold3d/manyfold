# frozen_string_literal: true

class Components::BaseButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(icon:, label:, href:, variant:, method: nil, icon_only: false)
    @icon = icon
    @label = label
    @href = href
    @variant = variant
    @method = method
    @icon_only = icon_only
  end

  def view_template
    helper(@href, method: @method, class: "btn btn-#{@variant}", aria: {label: @icon_only ? @label : nil}) do
      if @icon
        Icon(icon: @icon, label: @label)
        whitespace
      end
      span { @label } unless @icon_only
    end
  end

  def helper(*args)
    raise NotImplementedError
  end
end
