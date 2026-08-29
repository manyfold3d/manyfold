# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Printers HTML UI" do
  let(:attrs) {
    {
      name: "GK3 Pro",
      endpoint: "http://10.0.0.199:3030",
      mainboard_id: "d307202d8c1e0100"
    }
  }

  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    # INIT-009/SPEC-004 · ADR D-2 — fleet HTML must not sync-fetch SDCP status per host.
    it "renders the fleet dashboard without invoking PrintHost#service" do
      host = create(:print_host, name: "GK3 Pro — garage")
      allow_any_instance_of(PrintHost).to receive(:service) do # rubocop:disable RSpec/AnyInstance
        raise "PrintHost#service must not be called on GET /printers HTML (INIT-009/SPEC-004)"
      end

      get printers_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Printers")
      expect(response.body).to include("GK3 Pro — garage")
      expect(response.body).to include("Scan network")
      expect(response.body).to include(printer_path(host))
      expect(response.body).to include('data-controller="printer-fleet"')
      expect(response.body).to include(status_printer_path(host))
      expect(response.body).to include("data-printer-fleet-status-url-value")
    end

    it "renders add printer form" do
      get new_printer_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Add a printer")
      expect(response.body).to include("Register manually")
    end

    it "renders monitor with pause/stop controls" do
      host = create(:print_host, :with_capabilities)
      service = instance_double(Print::SdcpService, normalized_status: {
        current_layer: 1, total_layers: 10, filename: "helmet.ctb", eta_seconds: 60, temp_uv_c: 40
      })
      allow_any_instance_of(PrintHost).to receive(:service).and_return(service) # rubocop:disable RSpec/AnyInstance

      get printer_path(host)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(host.name)
      expect(response.body).to include("Pause")
      expect(response.body).to include("Stop")
      expect(response.body).to include(snapshot_printer_path(host))
    end

    it "shows unsupported banner for bambu-named hosts" do
      host = create(:print_host, name: "Workbench X1C", brand: "Bambu Lab")
      get printer_path(host)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("reference only")
      expect(response.body).not_to include(pause_printer_path(host))
    end

    it "creates via HTML form" do
      expect {
        post printers_path, params: {printer: attrs}
      }.to change(PrintHost, :count).by(1)
      expect(response).to redirect_to(printer_path(PrintHost.last))
    end

    it "hides send when gate fails and shows reasons via eligibility JSON" do
      host = create(:print_host, :with_capabilities, native_formats: %w[jxs])
      model = create(:model)
      file = create(:model_file, model: model, filename: "plate.ctb")

      get send_eligibility_model_model_file_path(model, file), params: {print_host_id: host.id}, as: :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["eligible"]).to be(false)
      expect(body["offered"]).to be(false)
      expect(body["reasons"]).not_to be_empty
    end

    it "sends sliced file when gate passes" do
      host = create(:print_host, :with_capabilities)
      model = create(:model)
      file = create(:model_file, model: model, filename: "plate.ctb")
      allow(SendFileToPrintHostJob).to receive(:perform_later)

      post send_file_printer_path(host), params: {model_id: model.to_param, model_file_id: file.to_param}
      expect(response).to redirect_to(printer_path(host))
      expect(SendFileToPrintHostJob).to have_received(:perform_later).with(host, file)
    end

    it "includes Printers nav link" do
      get printers_path
      expect(response.body).to include("nav-link-printers")
      expect(response.body).to include(">Printers<")
    end
  end

  context "when signed in", :as_contributor do
    it "forbids fleet HTML" do
      get printers_path
      expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
    end
  end
end
