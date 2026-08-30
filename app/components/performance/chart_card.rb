# frozen_string_literal: true

# INIT-013 follow-up — SVG line/area chart (replaces unreadable full-height bar slabs).
class Components::Performance::ChartCard < Components::Base
  register_element :svg
  register_element :polyline
  register_element :path
  register_element :circle
  register_element :line

  WIDTH = 400.0
  HEIGHT = 160.0
  PAD_L = 8.0
  PAD_R = 8.0
  PAD_T = 12.0
  PAD_B = 8.0

  def initialize(title:, subtitle:, series:, unit: nil, mode: :area, legend: nil)
    @title = title
    @subtitle = subtitle
    @unit = unit
    @series = Array(series)
    @mode = mode
    @legend = legend
  end

  def view_template
    article(
      class: card_classes,
      data: {region: "performance-chart"}
    ) do
      header_row
      if plottable?
        chart_body
      else
        empty_state
      end
    end
  end

  private

  def card_classes
    "bg-secondary-50 dark:bg-secondary-900 border border-secondary-200 dark:border-secondary-700 " \
      "rounded-xl p-5 flex flex-col gap-4 min-w-0 shadow-sm"
  end

  def header_row
    div(class: "flex items-start justify-between gap-3") do
      div(class: "min-w-0") do
        h3(class: "text-base font-semibold text-secondary-950 dark:text-white m-0") { @title }
        p(class: "text-sm text-secondary-600 dark:text-secondary-300 m-0 mt-1") { @subtitle }
      end
      if @unit.present?
        span(class: "text-xs font-semibold text-primary-700 dark:text-primary-300 shrink-0") { @unit }
      elsif @legend.present?
        div(class: "flex items-center gap-3 shrink-0 text-xs text-secondary-600 dark:text-secondary-300") do
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

  def empty_state
    div(class: "h-48 flex flex-col items-center justify-center gap-1 text-sm text-secondary-600 dark:text-secondary-300 border border-dashed border-secondary-300 dark:border-secondary-600 rounded-lg bg-secondary-100/50 dark:bg-secondary-950/40") do
      p(class: "m-0 font-medium text-secondary-800 dark:text-secondary-100") { t("performance.index.charts.empty") }
      if @series.size == 1
        p(class: "m-0 text-xs text-secondary-500") do
          t("performance.index.charts.single_point", value: format_y(@series.first[:y]))
        end
      end
    end
  end

  def chart_body
    points = scaled_points(:y)
    overlay = scaled_points(:y2) if has_overlay?

    div(class: "w-full", role: "img", "aria-label": @title) do
      svg(
        viewBox: "0 0 #{WIDTH.to_i} #{HEIGHT.to_i}",
        class: "w-full h-48 block",
        preserveAspectRatio: "none"
      ) do
        # Baseline
        line(
          x1: PAD_L, y1: HEIGHT - PAD_B, x2: WIDTH - PAD_R, y2: HEIGHT - PAD_B,
          class: "stroke-secondary-300 dark:stroke-secondary-600",
          stroke_width: 1
        )
        if @mode == :area
          path(d: area_path(points), class: "fill-primary-500/25 dark:fill-primary-400/20", stroke: "none")
          polyline(
            points: polyline_points(points),
            fill: "none",
            class: "stroke-primary-600 dark:stroke-primary-400",
            stroke_width: 2.5,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          )
        else
          polyline(
            points: polyline_points(points),
            fill: "none",
            class: "stroke-success dark:stroke-success",
            stroke_width: 2.5,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          )
        end
        if overlay
          polyline(
            points: polyline_points(overlay),
            fill: "none",
            class: "stroke-warning",
            stroke_width: 2,
            stroke_dasharray: "6 4",
            stroke_linecap: "round",
            stroke_linejoin: "round"
          )
        end
        # End dots for readability on sparse series
        last = points.last
        circle(cx: last[0], cy: last[1], r: 3.5, class: "fill-primary-600 dark:fill-primary-300") if @mode == :area
        circle(cx: last[0], cy: last[1], r: 3.5, class: "fill-success") if @mode != :area
      end
      div(class: "flex justify-between text-[11px] font-medium text-secondary-600 dark:text-secondary-300 mt-1 tabular-nums") do
        span { format_bucket(@series.first[:label]) }
        if @series.size > 2
          mid = @series[@series.size / 2]
          span { format_bucket(mid[:label]) }
        end
        span { format_bucket(@series.last[:label]) }
      end
      # Peak / latest callouts so sparse windows stay useful
      div(class: "flex flex-wrap gap-x-4 gap-y-1 text-xs text-secondary-700 dark:text-secondary-200 mt-2 tabular-nums") do
        span { t("performance.index.charts.latest", value: format_y(@series.last[:y])) }
        span { t("performance.index.charts.peak", value: format_y(@series.map { |p| p[:y].to_f }.max)) }
        span { t("performance.index.charts.buckets", count: @series.size) }
      end
    end
  end

  def plottable?
    @series.size >= 2
  end

  def has_overlay?
    @series.any? { |p| p[:y2] }
  end

  def scaled_points(key)
    values = @series.map { |p| p[key].to_f }
    max_y = [values.max, 1.0].max
    min_y = [values.min, 0.0].min
    span = [(max_y - min_y), max_y * 0.05, 1.0].max
    n = @series.size
    @series.each_with_index.map do |_p, i|
      x = PAD_L + (i.to_f / (n - 1)) * (WIDTH - PAD_L - PAD_R)
      y_norm = (values[i] - min_y) / span
      y = HEIGHT - PAD_B - (y_norm * (HEIGHT - PAD_T - PAD_B))
      [x.round(2), y.round(2)]
    end
  end

  def polyline_points(points)
    points.map { |x, y| "#{x},#{y}" }.join(" ")
  end

  def area_path(points)
    return "" if points.empty?

    base_y = HEIGHT - PAD_B
    first = points.first
    last = points.last
    mid = points.map { |x, y| "L #{x} #{y}" }.join(" ")
    "M #{first[0]} #{base_y} #{mid} L #{last[0]} #{base_y} Z"
  end

  def format_bucket(raw)
    s = raw.to_s
    return s if s.length < 11

    "#{s[9, 2]}:#{s[11, 2]}"
  end

  def format_y(value)
    v = value.to_f
    if v == v.to_i
      v.to_i.to_s
    else
      Kernel.format("%.1f", v)
    end
  end
end
