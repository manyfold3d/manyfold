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
      file = instance_double(ModelFile)
      expect {
        print_host.print_later(file: file)
      }.to have_enqueued_job(SendFileToPrintHostJob).with(print_host, file)
    end
  end
end
