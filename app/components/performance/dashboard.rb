# frozen_string_literal: true

# INIT-013/SPEC-004 — Phlex performance dashboard (Figma 29:297 adapted to Manyfold tokens).
class Components::Performance::Dashboard < Components::Base
  def initialize(telemetry:)
    @telemetry = telemetry
  end

  def view_template
    div(
      class: "flex items-stretch gap-0 -mx-4 sm:-mx-6 lg:-mx-8 min-h-[calc(100vh-8rem)] bg-secondary-50 dark:bg-secondary-950",
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
        h1(class: "text-2xl font-bold text-secondary-900 dark:text-secondary-50 m-0") do
          t("performance.index.heading")
        end
        p(class: "text-sm text-secondary-500 m-0") { t("performance.index.subtitle") }
      end
      span(
        class: "inline-flex items-center gap-2 rounded-full border border-secondary-200 dark:border-secondary-700 bg-surface px-3 py-1.5 text-sm text-secondary-700 dark:text-secondary-200"
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
        tone: :success,
        sparkline_values: sparkline_from_response
      )
      render Components::Performance::KpiCard.new(
        label: t("performance.index.kpi.p95"),
        value: format_ms(@telemetry.p95),
        tone: :warning,
        sparkline_values: sparkline_from_response
      )
      render Components::Performance::KpiCard.new(
        label: t("performance.index.kpi.p99"),
        value: format_ms(@telemetry.p99),
        tone: :danger,
        sparkline_values: sparkline_from_response
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
        mode: :bars
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
      h2(class: "text-sm font-semibold uppercase tracking-wide text-secondary-500 m-0") do
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
          value: t("performance.index.na")
        )
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.apdex"),
          value: t("performance.index.na")
        )
        render Components::Performance::SecondaryStat.new(
          label: t("performance.index.secondary.avg_db"),
          value: format_ms(@telemetry.avg_db_ms)
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

  def sparkline_from_response
    series = @telemetry.response_series
    return [0, 0] if series.blank?

    series.last(12).map { |p| p[:avg].to_f }
  end

  def throughput_series
    @telemetry.throughput.map { |p| {label: p[:datetime], y: p[:rpm].to_f} }
  end

  def response_series
    p95 = @telemetry.p95
    @telemetry.response_series.map do |p|
      {
        label: p[:datetime],
        y: p[:avg].to_f,
        y2: p95 # overlay constant p95 threshold when available
      }
    end
  end
end
