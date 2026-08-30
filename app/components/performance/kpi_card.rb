# frozen_string_literal: true

# INIT-013 follow-up — high-contrast KPI tile (dark-mode safe).
class Components::Performance::KpiCard < Components::Base
  def initialize(label:, value:, tone:, sparkline_values:, hint: nil)
    @label = label
    @value = value
    @tone = tone
    @sparkline_values = sparkline_values
    @hint = hint
  end

  def view_template
    article(
      class: "bg-secondary-50 dark:bg-secondary-900 border border-secondary-200 dark:border-secondary-700 " \
             "rounded-xl p-5 flex items-start justify-between gap-3 min-w-0 shadow-sm",
      data: {region: "performance-kpi"}
    ) do
      div(class: "min-w-0 flex flex-col gap-2") do
        p(class: "text-[11px] font-semibold uppercase tracking-wide text-secondary-600 dark:text-secondary-300 m-0") { @label }
        p(class: "text-3xl font-bold tabular-nums text-secondary-950 dark:text-white m-0 leading-none") { @value }
        if @hint.present?
          p(class: "text-xs text-secondary-600 dark:text-secondary-300 m-0") { @hint }
        end
        span(class: badge_classes) { badge_label }
      end
      render Components::Performance::Sparkline.new(values: @sparkline_values, tone: @tone)
    end
  end

  private

  def badge_label
    case @tone
    when :warning then t("performance.index.kpi.warning")
    when :danger then t("performance.index.kpi.critical")
    else t("performance.index.kpi.healthy")
    end
  end

  def badge_classes
    base = "inline-flex w-fit items-center rounded-md px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide"
    case @tone
    when :warning
      "#{base} bg-warning/20 text-warning"
    when :danger
      "#{base} bg-danger/20 text-danger"
    else
      "#{base} bg-success/20 text-success"
    end
  end
end
