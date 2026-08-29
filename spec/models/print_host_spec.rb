# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrintHost do
  describe "creating valid objects" do
    let(:attributes) { attributes_for(:print_host) }

    it "can be created with valid data" do
      expect(described_class.create(attributes)).to be_valid
    end

    it "requires a name" do
      expect(described_class.create(attributes.except(:name))).not_to be_valid
    end

    it "requires an endpoint" do
      expect(described_class.create(attributes.except(:endpoint))).not_to be_valid
    end

    it "requires a protocol" do
      expect(described_class.create(attributes.except(:protocol))).not_to be_valid
    end

    it "requires a VALID protocol" do
      expect(described_class.create(attributes.merge(protocol: "octoprint"))).not_to be_valid
    end

    it "accepts protocol sdcp with mainboard_id" do
      host = described_class.create(attributes.merge(protocol: "sdcp", mainboard_id: "d307202d8c1e0100"))
      expect(host).to be_valid
      expect(host.mainboard_id).to eq("d307202d8c1e0100")
    end

    it "rejects non-http endpoints" do
      expect(described_class.create(attributes.merge(endpoint: "rtsp://10.0.0.199:554/video"))).not_to be_valid
    end

    it "rejects public IP endpoints" do
      expect(described_class.create(attributes.merge(endpoint: "http://8.8.8.8:3030"))).not_to be_valid
    end

    it "rejects malformed mainboard_id" do
      expect(described_class.create(attributes.merge(mainboard_id: "not-hex!"))).not_to be_valid
    end

    it "allows blank mainboard_id until discover" do
      expect(described_class.create(attributes.merge(mainboard_id: nil))).to be_valid
    end

    it "rewrites bare SDCP http://IP endpoints to :3030" do
      host = described_class.create(attributes.merge(endpoint: "http://10.0.0.199"))
      expect(host).to be_valid
      expect(host.endpoint).to eq("http://10.0.0.199:3030")
    end
  end

  describe "capabilities (INIT-008/SPEC-002)" do
    it "persists identity and build volume fields" do
      host = create(:print_host, :with_capabilities)
      expect(host.brand).to eq("UniFormation")
      expect(host.machine_model).to eq("GK3 Pro")
      expect(host.firmware).to eq("1.2.3")
      expect(host.mac_address).to eq("AA:BB:CC:DD:EE:FF")
      expect(host.resolution_w).to eq(7680)
      expect(host.resolution_h).to eq(4320)
      expect(host.build_x_mm).to eq(228.0)
      expect(host.build_y_mm).to eq(128.0)
      expect(host.build_z_mm).to eq(260.0)
      expect(host.native_formats).to eq(%w[ctb jxs])
      expect(host.fep_cycles).to eq(120)
      expect(host.lcd_hours).to eq(48.5)
      expect(host.storage_bytes_used).to eq(1_073_741_824)
      expect(host.storage_bytes_total).to eq(8_589_934_592)
    end

    it "exposes resolution_label" do
      host = build(:print_host, resolution_w: 7680, resolution_h: 4320)
      expect(host.resolution_label).to eq("7680×4320")
    end

    it "prefers native_formats for capability_formats" do
      host = build(:print_host, native_formats: %w[ctb])
      expect(host.capability_formats).to eq(%w[ctb])
    end

    it "rejects negative fep_cycles" do
      expect(build(:print_host, fep_cycles: -1)).not_to be_valid
    end
  end

  context "with a valid print host" do
    let(:print_host) { create(:print_host) }

    it "lists SDCP input types (CTB / JXS)" do
      expect(print_host.input_types).to include(Mime[:chitubox], Mime[:jxs])
    end

    it "returns an SdcpService" do
      expect(print_host.service).to be_a(Print::SdcpService)
    end

    it "enqueues SendFileToPrintHostJob" do
      file = create(:model_file)
      expect {
        print_host.print_later(file: file)
      }.to have_enqueued_job(SendFileToPrintHostJob).with(print_host, file)
    end

    it "has print studio associations" do
      expect(print_host).to respond_to(:print_jobs, :sliced_artifacts, :resin_bottles, :print_vats)
    end
  end
end
