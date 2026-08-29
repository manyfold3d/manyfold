# frozen_string_literal: true

class Components::PrinterStatusBadge < Components::Base
  STATUSES = %w[printing idle offline unsupported paused].freeze

  def initialize(status:, label: nil)
    @status = status.to_s.downcase
    @status = "idle" unless STATUSES.include?(@status)
    @label = label
  end

  def view_template
    span(class: wrapper_class) do
      span(class: "size-1.5 rounded-full shrink-0 #{dot_class}", aria: {hidden: true})
      span { @label.presence || t("printers.status.#{@status}") }
    end
  end

  private

  def wrapper_class
    base = "inline-flex items-center gap-1.5 px-2 py-1 rounded text-[11px] font-medium"
    case @status
    when "printing"
      "#{base} bg-primary-50 text-success dark:bg-primary-950/40 dark:text-success"
    when "paused"
      "#{base} bg-warning/20 text-warning"
    when "unsupported"
      "#{base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400"
    when "offline"
      "#{base} bg-secondary-100 text-secondary-500 dark:bg-secondary-800 dark:text-secondary-500"
    else
      "#{base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400"
    end
  end

  def dot_class
    case @status
    when "printing" then "bg-success"
    when "paused" then "bg-warning"
    when "offline", "unsupported" then "bg-secondary-500"
    else "bg-secondary-400"
    end
  end
end
