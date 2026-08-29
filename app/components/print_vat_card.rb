# frozen_string_literal: true

# Vat registry card with health badge + swap form (INIT-008/SPEC-007 · Figma 23:1635).
class Components::PrintVatCard < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :policy

  def initialize(vat:, bottles: [])
    @vat = vat
    @bottles = bottles
  end

  def view_template
    article(class: "rounded-2xl border border-[#332623] bg-[#1a1311] p-5 flex flex-col gap-4") do
      div(class: "flex items-start justify-between gap-3") do
        h3(class: "text-lg font-semibold text-surface m-0") { @vat.identity }
        health_badge
      end

      dl(class: "m-0 space-y-3 text-sm") do
        div do
          dt(class: "font-mono text-[11px] uppercase tracking-wide text-secondary-500 m-0") do
            t("consumables.vat.assigned_to")
          end
          dd(class: "m-0 mt-1 font-medium #{assigned? ? "text-secondary-200" : "text-surface"}") do
            assigned? ? @vat.print_host.name : t("consumables.vat.unassigned")
          end
        end
        div do
          dt(class: "font-mono text-[11px] uppercase tracking-wide text-secondary-500 m-0") do
            t("consumables.vat.liquid_profile")
          end
          dd(class: "m-0 mt-1 #{profile_class}") { liquid_label }
        end
      end

      if policy(@vat).update?
        form_with url: swap_print_vat_path(@vat), method: :post, class: "mt-auto space-y-3" do
          label(class: "block text-[11px] font-mono uppercase text-secondary-500") do
            t("consumables.vat.swap_label")
          end
          select(
            name: "resin_bottle_id",
            class: "w-full rounded-lg border border-[#332623] bg-[#120f0d] text-surface px-3 py-2 text-sm"
          ) do
            option(value: "") { t("consumables.vat.unassign_resin") }
            @bottles.each do |bottle|
              label = [bottle.brand, bottle.color].compact.reject(&:blank?).join(" ")
              option(value: bottle.id.to_s, selected: bottle.id == @vat.resin_bottle_id ? "selected" : nil) { label }
            end
          end
          input(
            type: "submit",
            value: t("consumables.vat.swap"),
            class: "w-full inline-flex items-center justify-center px-4 py-2 rounded-lg bg-surface border border-secondary-300 text-secondary-900 text-sm font-medium cursor-pointer"
          )
        end
      end
    end
  end

  private

  def health_badge
    level = PrintConsumablesHelper.vat_health_level(@vat)
    classes = case level
    when :danger
      "bg-danger/20 text-danger border-danger/40"
    when :warning
      "bg-warning/20 text-warning border-warning/40"
    else
      "bg-success/15 text-success border-success/30"
    end
    span(class: "inline-flex items-center rounded px-2 py-0.5 text-[10px] font-mono font-semibold uppercase border #{classes}") do
      plain t("consumables.vat.cycles_badge", count: @vat.fep_cycles)
      whitespace
      plain "·"
      whitespace
      plain t("consumables.vat.health.#{level}")
    end
  end

  def assigned?
    @vat.print_host.present?
  end

  def liquid_label
    bottle = @vat.resin_bottle
    return t("consumables.vat.no_resin") if bottle.blank?

    [bottle.brand, bottle.color].compact.reject(&:blank?).join(" ")
  end

  def profile_class
    @vat.resin_bottle.present? ? "text-primary-500 font-medium" : "text-secondary-400"
  end
end
