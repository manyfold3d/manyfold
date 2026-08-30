# frozen_string_literal: true

# INIT-013/SPEC-004 — secondary operational metric tile.
class Components::Performance::SecondaryStat < Components::Base
  def initialize(label:, value:, hint: nil)
    @label = label
    @value = value
    @hint = hint
  end

  def view_template
    article(
      class: "bg-surface border border-secondary-200 dark:border-secondary-700 rounded-xl p-4 flex flex-col gap-1 min-w-0",
      data: {region: "performance-secondary-stat"}
    ) do
      p(class: "text-[11px] font-medium uppercase tracking-wide text-secondary-500 m-0") { @label }
      p(class: "text-xl font-bold tabular-nums text-secondary-900 dark:text-secondary-100 m-0") { @value }
      p(class: "text-xs text-secondary-400 m-0") { @hint } if @hint.present?
    end
  end
end
