# frozen_string_literal: true

# Outcome pill for history rows / completed queue cards (Figma 14 / 13).
class Components::PrintOutcomeBadge < Components::Base
  def initialize(outcome:)
    @outcome = outcome.to_s.downcase.presence || "unknown"
  end

  def view_template
    span(class: wrapper_class) { label }
  end

  private

  def label
    t("print_jobs.outcomes.#{@outcome}", default: @outcome.upcase)
  end

  def wrapper_class
    base = "inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wide"
    case @outcome
    when "succeeded", "success"
      "#{base} bg-success/20 text-success"
    when "failed", "failure"
      "#{base} bg-danger/20 text-danger"
    when "cancelled", "canceled"
      "#{base} bg-transparent border border-warning text-warning"
    else
      "#{base} bg-transparent border border-secondary-500 text-secondary-400"
    end
  end
end
