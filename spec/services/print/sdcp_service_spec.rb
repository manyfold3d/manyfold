# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::SdcpService do
  subject(:service) { described_class.new(print_host: print_host, session: session) }

  let(:print_host) { build(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100") }
  let(:session) { instance_double(Print::SdcpService::WebsocketSession) }

  describe "#ok?" do
    it "is true when Cmd 0 Ack is 0" do
      allow(session).to receive(:call).with(hash_including(cmd: 0)).and_return({"Ack" => 0})
      expect(service.ok?).to be(true)
    end

    it "is false when Cmd 0 raises" do
      allow(session).to receive(:call).and_raise(Print::SdcpService::AckError.new(cmd: 0, ack: 1))
      expect(service.ok?).to be(false)
    end
  end

  describe "#status" do
    it "returns Cmd 0 payload" do
      allow(session).to receive(:call).with(hash_including(cmd: 0)).and_return({"Ack" => 0})
      expect(service.status).to eq({"Ack" => 0})
    end

    it "fails loud on non-zero Ack" do
      allow(session).to receive(:call).with(hash_including(cmd: 0)).and_return({"Ack" => 1})
      expect { service.status }.to raise_error(Print::SdcpService::AckError)
    end
  end

  describe "#attributes" do
    it "requests Cmd 1 with attributes collect mode" do
      attrs = {"MachineName" => "GK3 GK3Pro", "MainboardID" => "d307202d8c1e0100"}
      allow(session).to receive(:call)
        .with(hash_including(cmd: 1, collect: :attributes))
        .and_return(attrs)
      expect(service.attributes).to eq(attrs)
    end
  end

  describe "#video_url" do
    it "normalizes VideoUrl missing host using print_host endpoint host" do
      allow(session).to receive(:call)
        .with(hash_including(cmd: 386, data: {"Enable" => 1}))
        .and_return({"Ack" => 0, "VideoUrl" => "rtsp://:554/video"})
      expect(service.video_url).to eq("rtsp://10.0.0.199:554/video")
    end
  end

  describe "print controls" do
    it "sends start/pause/stop/continue cmds" do
      allow(session).to receive(:call).and_return({"Ack" => 0})
      service.start_print(filename: "part.ctb")
      service.pause_print
      service.stop_print
      service.continue_print
      expect(session).to have_received(:call).with(hash_including(cmd: 128, data: hash_including("Filename" => "part.ctb")))
      expect(session).to have_received(:call).with(hash_including(cmd: 129))
      expect(session).to have_received(:call).with(hash_including(cmd: 130))
      expect(session).to have_received(:call).with(hash_including(cmd: 131))
    end
  end

  describe "#upload" do
    it "rejects unsupported file types before HTTP" do
      expect {
        service.upload(io: StringIO.new("x"), filename: "model.stl")
      }.to raise_error(Print::SdcpService::UnsupportedFileType)
    end

    it "posts multipart chunks then starts when requested" do
      # Stub HTTP upload without live printer
      stub_request(:post, "http://10.0.0.199:3030/uploadFile/upload")
        .to_return(status: 200, body: {code: "000000", success: true, data: {}}.to_json,
          headers: {"Content-Type" => "application/json"})
      allow(session).to receive(:call).with(hash_including(cmd: 128)).and_return({"Ack" => 0})

      result = service.upload(io: StringIO.new("ctb-bytes"), filename: "part.ctb", start: true)
      expect(result[:filename]).to eq("part.ctb")
      expect(result[:bytes]).to eq(9)
      expect(session).to have_received(:call).with(hash_including(cmd: 128))
    end
  end

  describe ".parse_discover_payload" do
    it "extracts JSON after M99999 prefix" do
      raw = 'M99999{"BrandName":"UniFormation","MainboardID":"d307202d8c1e0100"}'
      expect(described_class.parse_discover_payload(raw)["BrandName"]).to eq("UniFormation")
    end
  end
end
