# frozen_string_literal: true

class Components::BaseButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  BASE_CLASSES = "inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg transition-colors focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2"

  VARIANT_CLASSES = {
    "primary" => "bg-primary-600 text-white hover:bg-primary-700",
    "secondary" => "bg-white border border-secondary-300 text-secondary-900 hover:bg-secondary-50 dark:bg-secondary-800 dark:border-secondary-600 dark:text-secondary-100 dark:hover:bg-secondary-700",
    "success" => "bg-success text-white hover:opacity-90",
    "danger" => "bg-danger text-white hover:opacity-90",
    "warning" => "bg-warning text-secondary-900 hover:opacity-90",
    "outline-primary" => "bg-transparent border border-primary-600 text-primary-600 hover:bg-primary-50 dark:text-primary-400 dark:border-primary-400 dark:hover:bg-primary-900/30",
    "outline-secondary" => "bg-transparent border border-secondary-300 text-secondary-700 hover:bg-secondary-50 dark:border-secondary-600 dark:text-secondary-100 dark:hover:bg-secondary-800",
    "outline-danger" => "bg-transparent border border-danger text-danger hover:bg-danger/10",
    "outline-warning" => "bg-transparent border border-warning text-warning hover:bg-warning/10"
  }.freeze

  def initialize(label:, href:, variant:, icon: nil, method: nil, icon_only: false, aria_label: nil, confirm: nil, data: {}, nofollow: nil, target: nil)
    @icon = icon
    @label = label
    @href = href
    @variant = variant.to_s
    @method = method
    @icon_only = icon_only
    @aria_label = aria_label
    @confirm = confirm
    @data = data
    @nofollow = nofollow
    @target = target
  end

  def view_template
    helper(
      @href,
      method: @method,
      class: button_class,
      rel: (@nofollow ? "nofollow" : nil),
      aria: {label: @aria_label || (@icon_only ? @label : nil)},
      data: {confirm: @confirm}.merge(@data),
      target: @target
    ) do
      if @icon
        Icon(icon: @icon, label: @label)
        whitespace
      end
      span(class: (@icon_only ? "sr-only" : nil)) { @label }
    end
  end

  def helper(*args)
    raise NotImplementedError
  end

  private

  def button_class
    variant_classes = VARIANT_CLASSES[@variant] || VARIANT_CLASSES["secondary"]
    [BASE_CLASSES, variant_classes].join(" ")
  end
end
