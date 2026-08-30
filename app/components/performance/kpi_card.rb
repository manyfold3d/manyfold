# frozen_string_literal: true

# INIT-013/SPEC-004 — p50 / p95 / p99 latency KPI tile.
class Components::Performance::KpiCard < Components::Base
  def initialize(label:, value:, tone:, sparkline_values:)
    @label = label
    @value = value
    @tone = tone
    @sparkline_values = sparkline_values
  end

  def view_template
    article(
      class: "bg-surface border border-secondary-200 dark:border-secondary-700 rounded-xl p-5 flex items-start justify-between gap-3 min-w-0",
      data: {region: "performance-kpi"}
    ) do
      div(class: "min-w-0 flex flex-col gap-2") do
        p(class: "text-[11px] font-medium uppercase tracking-wide text-secondary-500 m-0") { @label }
        p(class: "text-2xl font-bold tabular-nums text-secondary-900 dark:text-secondary-100 m-0") { @value }
        span(class: badge_classes) { t("performance.index.kpi.active") }
      end
      render Components::Performance::Sparkline.new(values: @sparkline_values, tone: @tone)
    end
  end

  private

  def badge_classes
    base = "inline-flex w-fit items-center rounded-md px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide"
    case @tone
    when :warning
      "#{base} bg-warning/15 text-warning"
    when :danger
      "#{base} bg-danger/15 text-danger"
    else
      "#{base} bg-success/15 text-success"
    end
  end
end
