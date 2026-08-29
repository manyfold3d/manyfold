# frozen_string_literal: true

# Resin inventory card with adjust-level form (INIT-008/SPEC-007 · Figma 23:1635).
class Components::ResinBottleCard < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberWithPrecision

  register_value_helper :policy

  def initialize(bottle:)
    @bottle = bottle
  end

  def view_template
    article(class: "rounded-2xl border border-[#332623] bg-[#1a1311] p-5 flex flex-col gap-4") do
      div(class: "flex items-start justify-between gap-3") do
        h3(class: "text-lg font-semibold text-surface m-0") { bottle_title }
        if policy(@bottle).update?
          button(
            type: "button",
            class: "inline-flex items-center justify-center px-3 py-1.5 rounded-lg bg-surface border border-secondary-300 text-secondary-900 text-sm font-medium shrink-0",
            data: {action: "click->resin-adjust#toggle"}
          ) { t("consumables.resin.adjust") }
        end
      end

      div(class: "space-y-2") do
        div(class: "bg-[#2f2723] h-2 rounded-full overflow-hidden") do
          div(
            class: "h-full rounded-full #{low? ? "bg-warning" : "bg-primary-600"}",
            style: "width: #{fill_pct}%"
          )
        end
        div(class: "flex items-baseline justify-between gap-2") do
          p(class: "font-mono text-sm text-surface m-0") do
            plain t("consumables.resin.volume",
              remaining: format_ml(@bottle.remaining_ml),
              capacity: format_ml(@bottle.capacity_ml))
          end
          if low?
            span(class: "inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-mono font-semibold uppercase bg-warning/20 text-warning") do
              t("consumables.resin.low")
            end
          end
        end
      end

      div(class: "flex flex-wrap gap-4 text-[13px] text-secondary-400") do
        span { t("consumables.resin.opened", date: opened_label) }
        span { t("consumables.resin.prints", count: 0) }
      end

      if policy(@bottle).update?
        div(class: "hidden pt-2 border-t border-[#332623]", data: {resin_adjust_target: "form"}) do
          form_with model: @bottle, url: resin_bottle_path(@bottle), method: :patch,
            class: "flex flex-wrap items-end gap-3" do |f|
            div(class: "grow min-w-[8rem]") do
              label(class: "block text-[11px] font-mono uppercase text-secondary-500 mb-1") do
                t("consumables.resin.remaining_label")
              end
              f.number_field :remaining_ml,
                step: 1,
                min: 0,
                max: @bottle.capacity_ml.to_f,
                class: "w-full rounded-lg border border-[#332623] bg-[#120f0d] text-surface px-3 py-2 text-sm font-mono"
            end
            f.submit t("consumables.resin.save"),
              class: "inline-flex items-center justify-center px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium cursor-pointer"
          end
        end
      end
    end
  end

  private

  def bottle_title
    [@bottle.brand, @bottle.color].compact.reject(&:blank?).join(" ")
  end

  def fill_pct
    PrintConsumablesHelper.resin_fill_pct(@bottle)
  end

  def low?
    PrintConsumablesHelper.resin_low?(@bottle)
  end

  def format_ml(value)
    number_with_precision(value, precision: 0, delimiter: ",")
  end

  def opened_label
    return t("consumables.resin.unopened") if @bottle.opened_on.blank?

    I18n.l(@bottle.opened_on, format: :long)
  end
end
