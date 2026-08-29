# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Printers API" do
  let(:attrs) {
    {
      name: "GK3 Pro",
      endpoint: "http://10.0.0.199:3030",
      mainboard_id: "d307202d8c1e0100"
    }
  }

  context "when signed out" do
    it "requires authentication" do
      get printers_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when signed in", :as_contributor do
    it "denies fleet index" do
      get printers_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "lists printers" do
      create(:print_host, name: "GK3 Pro")
      get printers_path, as: :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["printers"].map { |p| p["name"] }).to include("GK3 Pro")
    end

    it "creates a printer without auto-persisting discover" do
      candidates = [{name: "Found", endpoint: "http://10.0.0.50:3030", mainboard_id: "aabbccddeeff0011"}]
      allow(Print::SdcpService).to receive(:discover_candidates).and_return(candidates)

      expect {
        post discover_printers_path, params: {hosts: ["10.0.0.255"]}, as: :json
      }.not_to change(PrintHost, :count)
      expect(response).to have_http_status(:success)
      expect(response.parsed_body["candidates"]).to eq(candidates.map { |c| c.stringify_keys })

      expect {
        post printers_path, params: {printer: attrs}, as: :json
      }.to change(PrintHost, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "rejects discover targets outside the private LAN allowlist" do
      post discover_printers_path, params: {hosts: ["1.1.1.1", "8.8.8.8"]}, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to match(/allowlisted/)
    end

    it "returns status JSON" do
      host = create(:print_host, :with_capabilities)
      status = {machine_status: [0], current_layer: 1, total_layers: 10}
      service = instance_double(Print::SdcpService, normalized_status: status)
      allow(PrintHost).to receive(:find).and_call_original
      allow_any_instance_of(PrintHost).to receive(:service).and_return(service) # rubocop:disable RSpec/AnyInstance

      get status_printer_path(host), as: :json
      expect(response).to have_http_status(:success)
      expect(response.parsed_body["status"]["current_layer"]).to eq(1)
    end

    # Socket.tcp(connect_timeout:) raises Errno::ETIMEDOUT — must soft-502, never 500.
    it "returns 502 JSON when SDCP connect times out (Errno::ETIMEDOUT)" do
      host = create(:print_host, :with_capabilities)
      allow(PrintHost).to receive(:find).and_call_original
      allow_any_instance_of(PrintHost).to receive(:service).and_raise(Errno::ETIMEDOUT) # rubocop:disable RSpec/AnyInstance

      get status_printer_path(host), as: :json
      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body["error"]).to be_present
    end

    it "updates printer settings" do
      host = create(:print_host, :with_capabilities)
      patch printer_path(host), params: {printer: {name: "Renamed GK3"}}, as: :json
      expect(response).to have_http_status(:success)
      expect(host.reload.name).to eq("Renamed GK3")
    end
  end
end
