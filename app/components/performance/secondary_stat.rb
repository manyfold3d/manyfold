# frozen_string_literal: true

# INIT-013 follow-up — high-contrast secondary metric tile.
class Components::Performance::SecondaryStat < Components::Base
  def initialize(label:, value:, hint: nil)
    @label = label
    @value = value
    @hint = hint
  end

  def view_template
    article(
      class: "bg-secondary-50 dark:bg-secondary-900 border border-secondary-200 dark:border-secondary-700 " \
             "rounded-xl p-4 flex flex-col gap-1 min-w-0 shadow-sm",
      data: {region: "performance-secondary-stat"}
    ) do
      p(class: "text-[11px] font-semibold uppercase tracking-wide text-secondary-600 dark:text-secondary-300 m-0") { @label }
      p(class: "text-2xl font-bold tabular-nums text-secondary-950 dark:text-white m-0") { @value }
      p(class: "text-xs text-secondary-600 dark:text-secondary-300 m-0") { @hint } if @hint.present?
    end
  end
end
