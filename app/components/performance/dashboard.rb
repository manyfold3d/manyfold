# frozen_string_literal: true

# INIT-013/SPEC-004 — Phlex performance dashboard (Figma 29:297 adapted to Manyfold tokens).
# Follow-up — contrast + SVG charts + real error/apdex metrics.
class Components::Performance::Dashboard < Components::Base
  def initialize(telemetry:)
    @telemetry = telemetry
  end

  def view_template
    div(
      class: "flex items-stretch gap-0 -mx-4 sm:-mx-6 lg:-mx-8 min-h-[calc(100vh-8rem)] bg-secondary-100 dark:bg-secondary-950",
      data: {region: "performance-dashboard"}
    ) do
      render Components::Performance::Sidebar.new
      main_panel
    end
  end

  private

  def main_panel
    div(class: "flex-1 min-w-0 flex flex-col gap-6 p-6 lg:p-8", data: {region: "performance-main"}) do
      header
      kpi_row
      charts_row
      secondary_stats
    end
  end

  def header
    div(class: "flex flex-wrap items-start justify-between gap-4", data: {region: "performance-header"}) do
      div(class: "min-w-0 space-y-1") do
        h1(class: "text-2xl font-bold text-secondary-950 dark:text-white m-0") do
          t("performance.index.heading")
        end
        p(class: "text-sm text-secondary-600 dark:text-secondary-300 m-0") { t("performance.index.subtitle") }
      end
      span(
        class: "inline-flex items-center gap-2 rounded-full border border-secondary-300 dark:border-secondary-600 " \
               "bg-secondary-50 dark:bg-secondary-900 px-3 py-1.5 text-sm font-medium text-secondary-800 dark:text-secondary-100"
      ) do
        span(class: "size-2 rounded-full bg-success", "aria-hidden": "true")
        plain status_label
      end
    end
  end

  def status_label
    if @telemetry.budget_exceeded
      t("performance.index.status.partial")
    else
      t("performance.index.status.operational")
    end
  end

  def kpi_row
    div(class: "grid gap-4 sm:grid-cols-3", data: {region: "performance-kpi-row"}) do
      render Components::Performance::KpiCard.new(
        label: t("performance.index.kpi.p50"),
        value: format_ms(@telemetry.p50),
        tone: kpi_tone(@telemetry.p50, warn: 300, crit: 800),
        sparkline_values: sparkline_from_response,
        hint: t("performance.index.kpi.hint_p50")
      )
      render Components::Performance::KpiCard.new(
        label: t("performance.index.kpi.p95"),
        value: format_ms(@telemetry.p95),
        tone: kpi_tone(@telemetry.p95, warn: 500, crit: 1500),
        sparkline_values: sparkline_from_response,
        hint: t("performance.index.kpi.hint_p95")
      )
      render Components::Performance::KpiCard.new(
        label: t("performance.index.kpi.p99"),
        value: format_ms(@telemetry.p99),
        tone: kpi_tone(@telemetry.p99, warn: 800, crit: 3000),
        sparkline_values: sparkline_from_response,
        hint: t("performance.index.kpi.hint_p99")
      )
    end
  end

  def charts_row
    div(class: "grid gap-4 lg:grid-cols-2", data: {region: "performance-charts"}) do
      render Components::Performance::ChartCard.new(
        title: t("performance.index.charts.throughput_title"),
        subtitle: t("performance.index.charts.throughput_subtitle"),
        unit: t("performance.index.charts.throughput_unit"),
        series: throughput_series,
        mode: :area
      )
      render Components::Performance::ChartCard.new(
        title: t("performance.index.charts.response_title"),
        subtitle: t("performance.index.charts.response_subtitle"),
        series: response_series,
        mode: :lines,
        legend: [
          {label: t("performance.index.charts.legend_avg"), dot_class: "bg-success"},
          {label: t("performance.index.charts.legend_p95"), dot_class: "bg-warning"}
        ]
      )
    end
  end

  def secondary_stats
    div(class: "space-y-3", data: {region: "performance-secondary"}) do
      h2(class: "text-sm font-semibold uppercase tracking-wide text-secondary-600 dark:text-secondary-300 m-0") do
        t("performance.index.secondary.heading")
      end
      div(class: "grid gap-4 sm:grid-cols-2 xl:grid-cols-4") do
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.requests_today"),
          value: format_count(@telemetry.sample_count),
          hint: t("performance.index.secondary.requests_hint")
        )
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.error_rate"),
          value: format_pct(@telemetry.error_rate),
          hint: t("performance.index.secondary.error_hint")
        )
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.apdex"),
          value: format_apdex(@telemetry.apdex),
          hint: t("performance.index.secondary.apdex_hint")
        )
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.avg_db"),
          value: format_ms(@telemetry.avg_db_ms),
          hint: t("performance.index.secondary.db_hint")
        )
      end
    end
  end

  def format_ms(value)
    return t("performance.index.na") if value.nil?

    t("performance.index.ms", value: Kernel.format("%.1f", value.to_f))
  end

  def format_count(value)
    value.to_i.to_s
  end

  def format_pct(value)
    return t("performance.index.na") if value.nil?

    t("performance.index.pct", value: Kernel.format("%.2f", value.to_f))
  end

  def format_apdex(value)
    return t("performance.index.na") if value.nil?

    Kernel.format("%.2f", value.to_f)
  end

  def kpi_tone(ms, warn:, crit:)
    return :success if ms.nil?

    if ms >= crit
      :danger
    elsif ms >= warn
      :warning
    else
      :success
    end
  end

  def sparkline_from_response
    series = @telemetry.response_series
    return [0, 0] if series.blank?

    series.last(12).map { |p| p[:avg].to_f }
  end

  def throughput_series
    @telemetry.throughput.map { |p| {label: p[:datetime], y: p[:rpm].to_f} }
  end

  def response_series
    @telemetry.response_series.map do |p|
      {
        label: p[:datetime],
        y: p[:avg].to_f,
        y2: p[:p95].to_f
      }
    end
  end
end
