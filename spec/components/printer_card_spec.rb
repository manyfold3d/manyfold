# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PrinterCard, type: :component do
  let(:printer) { create(:print_host, name: "GK3 Pro — garage") }

  it "renders open monitor link and name" do
    html = render described_class.new(printer: printer, status: {})
    expect(html).to include("GK3 Pro — garage")
    expect(html).to include("Open monitor")
    expect(html).to include("/printers/#{printer.id}")
  end

  it "wires printer-fleet Stimulus when status_url is present" do
    html = render described_class.new(
      printer: printer,
      status_url: "/printers/#{printer.id}/status",
      snapshot_url: "/printers/#{printer.id}/snapshot"
    )
    expect(html).to include('data-controller="printer-fleet"')
    expect(html).to include("data-printer-fleet-status-url-value")
    expect(html).to include("/printers/#{printer.id}/status")
    expect(html).to include("data-printer-fleet-target=\"badge\"")
  end

  it "marks bambu-named hosts as unsupported" do
    bambu = create(:print_host, name: "Workbench X1C", brand: "Bambu")
    html = render described_class.new(printer: bambu, status: {})
    expect(html).to include("Unsupported")
    expect(html).to include("send is disabled")
  end
end
