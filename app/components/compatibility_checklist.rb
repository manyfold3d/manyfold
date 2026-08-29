# frozen_string_literal: true

# Compatibility gate checklist for printer settings sidebar (INIT-008/SPEC-007).
class Components::CompatibilityChecklist < Components::Base
  def initialize(rules:)
    @rules = Array(rules)
  end

  def view_template
    ul(class: "list-none m-0 p-0 space-y-3") do
      @rules.each { |rule| rule_row(rule) }
    end
  end

  private

  def rule_row(rule)
    pass = rule[:pass]
    li(class: "flex items-start gap-3") do
      span(class: "mt-0.5 shrink-0 #{pass ? "text-success" : "text-danger"}", aria: {hidden: true}) do
        Icon(icon: pass ? "check-circle-fill" : "x-circle-fill", label: pass ? "pass" : "fail")
      end
      div(class: "min-w-0") do
        p(class: "m-0 text-sm font-medium text-surface") { rule[:title] }
        p(class: "m-0 mt-0.5 text-[13px] text-secondary-400") { rule[:detail] }
      end
    end
  end
end
