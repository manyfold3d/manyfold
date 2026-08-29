# frozen_string_literal: true

# Send-from-library dialog (Figma 15:586). Sliced-file path only; Prepare/Open Slicer stubbed (GR-001).
class Components::SendPrintDialog < Components::Base
  register_value_helper :policy

  def initialize(model:, file:, printers:, eligibility_url:)
    @model = model
    @file = file
    @printers = Array(printers)
    @eligibility_url = eligibility_url
  end

  def render?
    @file.sliced_for_print? && policy(PrintHost).control?
  end

  def view_template
    div(class: "relative", data: {
      controller: "dialog send-print",
      send_print_eligibility_url_value: @eligibility_url,
      send_print_model_id_value: @model.to_param,
      send_print_file_id_value: @file.to_param
    }) do
      button(
        type: "button",
        class: "inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-primary-600 text-white text-sm font-medium hover:bg-primary-700",
        data: {action: "click->dialog#open"},
        aria: {haspopup: "dialog"}
      ) do
        Icon(icon: "printer", label: t("printers.send.open"))
        whitespace
        plain t("printers.send.open")
      end

      dialog(
        class: "relative max-w-xl w-full max-h-[90vh] overflow-auto rounded-2xl bg-[#1a1311] border border-[#332623] shadow-xl p-0 text-surface backdrop:bg-secondary-950/70",
        id: "send-print-dialog",
        "aria-labelledby": "send-print-dialog-label",
        "aria-modal": "true",
        data: {dialog_target: "dialog"}
      ) do
        div(class: "flex flex-col gap-6 p-8") do
          header_block
          printer_select
          prepare_stub
          sliced_path
          button(
            type: "button",
            class: "text-primary-600 text-sm font-medium self-center bg-transparent border-0 cursor-pointer",
            data: {action: "click->dialog#close"}
          ) { t("general.cancel") }
        end
      end
    end
  end

  private

  def header_block
    div(class: "flex flex-col gap-1.5") do
      h1(class: "font-display font-bold text-2xl text-surface m-0", id: "send-print-dialog-label") do
        t("printers.send.title")
      end
      p(class: "text-sm text-secondary-300 m-0") do
        t("printers.send.subtitle", name: @model.name)
      end
    end
  end

  def printer_select
    div(class: "flex flex-col gap-2 w-full") do
      label(class: "text-[11px] font-medium text-secondary-500 uppercase tracking-wide", for: "send-print-host") do
        t("printers.send.target_printer")
      end
      select(
        id: "send-print-host",
        name: "print_host_id",
        class: "w-full bg-[#261c1a] border border-[#332623] rounded-lg px-4 py-3 text-sm text-surface",
        data: {
          send_print_target: "printer",
          action: "change->send-print#refreshEligibility"
        }
      ) do
        option(value: "") { t("printers.send.choose_printer") }
        @printers.each do |host|
          label_text = if host.unsupported_for_send?
            t("printers.send.printer_unsupported_option", name: host.name)
          else
            host.name
          end
          if host.unsupported_for_send?
            option(value: host.id.to_s, disabled: true) { label_text }
          else
            option(value: host.id.to_s) { label_text }
          end
        end
      end
      ul(
        class: "text-sm text-danger list-disc ps-5 m-0 hidden",
        data: {send_print_target: "reasons"}
      )
    end
  end

  def prepare_stub
    div(class: "bg-[#261c1a] border border-[#332623] rounded-xl p-5 flex flex-col gap-4 w-full opacity-60") do
      div(class: "flex flex-col gap-1.5") do
        h2(class: "text-base font-semibold text-surface m-0") { t("printers.send.prepare_title") }
        p(class: "text-[13px] text-secondary-300 m-0") { t("printers.send.prepare_help") }
      end
      button(
        type: "button",
        class: "inline-flex items-center justify-center px-4 py-2 rounded-lg bg-primary-600/50 text-white text-sm font-medium cursor-not-allowed",
        disabled: true,
        title: t("printers.send.prepare_stub_title"),
        aria: {disabled: true}
      ) { t("printers.send.prepare_cta") }
      p(class: "text-xs text-secondary-500 m-0") { t("printers.send.prepare_stub_note") }
    end
  end

  def sliced_path
    div(class: "bg-[#100b09] border border-[#332623] rounded-xl p-5 flex flex-col gap-4 w-full") do
      div(class: "flex flex-col gap-1.5") do
        h2(class: "text-base font-semibold text-secondary-300 m-0") { t("printers.send.sliced_title") }
        p(class: "text-[13px] text-secondary-500 m-0") { t("printers.send.sliced_help") }
      end
      form(
        action: "#",
        method: "post",
        data: {send_print_target: "form"}
      ) do
        input(type: "hidden", name: "authenticity_token", value: "", data: {send_print_target: "csrf"})
        input(type: "hidden", name: "model_id", value: @model.to_param)
        input(type: "hidden", name: "model_file_id", value: @file.to_param)
        button(
          type: "submit",
          class: "inline-flex items-center justify-center px-4 py-2 rounded-lg bg-surface border border-secondary-300 text-secondary-900 text-sm font-medium disabled:opacity-40 disabled:cursor-not-allowed",
          disabled: true,
          data: {send_print_target: "submit"}
        ) { t("printers.send.sliced_cta", ext: @file.extension.upcase) }
      end
      p(class: "text-xs text-secondary-500 m-0") { t("printers.send.slicer_stub_note") }
    end
  end
end
