# frozen_string_literal: true

# INIT-013/SPEC-004 — CSS sparkline for KPI cards (no Chart.js).
class Components::Performance::Sparkline < Components::Base
  def initialize(values:, tone: :success)
    @values = Array(values).map(&:to_f)
    @tone = tone
  end

  def view_template
    vals = normalized
    div(
      class: "flex items-end gap-0.5 w-20 h-8 shrink-0 opacity-90",
      "aria-hidden": "true"
    ) do
      vals.each do |h|
        div(class: "flex-1 rounded-sm #{bar_class}", style: "height: #{h}%")
      end
    end
  end

  private

  def bar_class
    case @tone
    when :warning then "bg-warning"
    when :danger then "bg-danger"
    else "bg-success"
    end
  end

  def normalized
    vals = @values
    vals = [0.0, 0.0] if vals.size < 2
    vals = vals.last(12)
    max = vals.max
    return Array.new(vals.size, 20) if max <= 0

    vals.map { |v| ((v / max) * 100).clamp(8, 100).round }
  end
end
