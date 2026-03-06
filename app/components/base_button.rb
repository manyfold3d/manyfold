# frozen_string_literal: true

class Components::BaseButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(label:, href:, variant:, icon: nil, method: nil, icon_only: false, aria_label: nil, confirm: nil, data: {}, nofollow: nil, target: nil, small: false, help: nil)
    @icon = icon
    @label = label
    @href = href
    @variant = variant
    @method = method
    @icon_only = icon_only
    @aria_label = aria_label
    @confirm = confirm
    @data = data
    @nofollow = nofollow
    @target = target
    @small = small
    @help = help
  end

  def view_template
    helper(@href, method: @method, class: "btn#{" btn-sm" if @small} btn-#{@variant}", rel: (@nofollow ? "nofollow" : nil), title: @help, aria: {label: @aria_label || (@icon_only ? @label : nil)}, data: {confirm: @confirm}.merge(@data), target: @target) do
      if @icon
        Icon(icon: @icon, label: @help || @label)
        whitespace
      end
      span(class: @icon_only ? "visually-hidden" : nil) { @label }
    end
  end

  def helper(*args)
    raise NotImplementedError
  end
end
