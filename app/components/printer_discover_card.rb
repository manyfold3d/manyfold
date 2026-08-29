# frozen_string_literal: true

class Components::PrinterDiscoverCard < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith

  def initialize(discover_url:)
    @discover_url = discover_url
  end

  def view_template
    article(
      class: "bg-[#1a1311] border border-dashed border-primary-600 rounded-2xl min-h-[418px] flex flex-col gap-5 items-center justify-center p-8 text-center",
      data: {controller: "printer-discover", printer_discover_url_value: @discover_url}
    ) do
      div(class: "bg-[#261c1a] rounded-full p-4 flex items-center justify-center") do
        Icon(icon: "search", label: t("printers.discover.title"))
      end
      div(class: "flex flex-col gap-2 items-center") do
        h2(class: "text-lg font-semibold text-surface m-0") { t("printers.discover.title") }
        p(class: "text-[13px] text-secondary-300 m-0 max-w-[300px]") { t("printers.discover.description") }
      end
      button(
        type: "button",
        class: "inline-flex items-center justify-center px-4 py-2 rounded-lg bg-surface border border-secondary-300 text-secondary-900 text-sm font-medium hover:bg-secondary-50",
        data: {action: "click->printer-discover#scan", printer_discover_target: "button"}
      ) { t("printers.discover.scan") }
      div(class: "w-full", data: {printer_discover_target: "results"}, id: "printer-discover-results")
    end
  end
end
