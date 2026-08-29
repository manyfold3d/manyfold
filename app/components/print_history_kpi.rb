# frozen_string_literal: true

# KPI tile for Print History summary row (Figma 14 Print History / 23:969).
class Components::PrintHistoryKpi < Components::Base
  def initialize(label:, value:, hint: nil)
    @label = label
    @value = value
    @hint = hint
  end

  def view_template
    article(class: "bg-[#1a1311] border border-[#332623] rounded-xl p-5 flex flex-col gap-1 min-w-0") do
      p(class: "text-[11px] font-medium text-secondary-500 uppercase tracking-wide m-0") { @label }
      p(class: "font-display font-bold text-3xl text-surface m-0 tabular-nums") { @value }
      p(class: "text-[12px] text-secondary-400 m-0") { @hint } if @hint.present?
    end
  end
end
