# frozen_string_literal: true

# INIT-013/SPEC-004 — CSS bar/line chart card (no Chart.js).
class Components::Performance::ChartCard < Components::Base
  def initialize(title:, subtitle:, series:, unit: nil, mode: :bars, legend: nil)
    @title = title
    @subtitle = subtitle
    @unit = unit
    @series = Array(series)
    @mode = mode
    @legend = legend
  end

  def view_template
    article(
      class: "bg-surface border border-secondary-200 dark:border-secondary-700 rounded-xl p-5 flex flex-col gap-4 min-w-0",
      data: {region: "performance-chart"}
    ) do
      header_row
      if @series.empty?
        div(class: "h-48 flex items-center justify-center text-sm text-secondary-400 border border-dashed border-secondary-200 dark:border-secondary-700 rounded-lg") do
          t("performance.index.charts.empty")
        end
      else
        chart_body
      end
    end
  end

  private

  def header_row
    div(class: "flex items-start justify-between gap-3") do
      div(class: "min-w-0") do
        h3(class: "text-base font-semibold text-secondary-900 dark:text-secondary-100 m-0") { @title }
        p(class: "text-sm text-secondary-500 m-0 mt-1") { @subtitle }
      end
      if @unit.present?
        span(class: "text-xs font-medium text-primary-600 dark:text-primary-400 shrink-0") { @unit }
      elsif @legend.present?
        div(class: "flex items-center gap-3 shrink-0 text-xs text-secondary-500") do
          @legend.each do |item|
            span(class: "inline-flex items-center gap-1.5") do
              span(class: "size-2 rounded-full #{item[:dot_class]}")
              plain item[:label]
            end
          end
        end
      end
    end
  end

  def chart_body
    heights = bar_heights
    div(class: "h-48 w-full flex flex-col gap-2", role: "img", "aria-label": @title) do
      div(class: "flex-1 flex items-end gap-px min-h-0") do
        heights.each_with_index do |h, i|
          point = @series[i]
          tip = "#{format_bucket(point[:label])}: #{point[:y]}"
          div(
            class: "flex-1 min-w-0 rounded-t-sm #{bar_fill_class(point)}",
            style: "height: #{h}%",
            title: tip
          )
        end
      end
      div(class: "flex justify-between text-[10px] text-secondary-400") do
        span { format_bucket(@series.first[:label]) }
        if @series.size > 2
          mid = @series[@series.size / 2]
          span { format_bucket(mid[:label]) }
        end
        span { format_bucket(@series.last[:label]) }
      end
    end
  end

  def bar_heights
    values = @series.map { |p| [p[:y].to_f, p[:y2].to_f].compact.max }
    max_y = [values.max, 1.0].max
    values.map { |v| ((v / max_y) * 100).clamp(2, 100).round }
  end

  def bar_fill_class(point)
    if @mode == :lines && point[:y2]
      "bg-warning/70"
    elsif @mode == :lines
      "bg-success/80"
    else
      "bg-primary-500/80"
    end
  end

  def format_bucket(raw)
    s = raw.to_s
    return s if s.length < 11

    # YYYYMMDDTHHMM → HH:MM
    "#{s[9, 2]}:#{s[11, 2]}"
  end
end
