# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::SdcpService do
  subject(:service) { described_class.new(print_host: print_host, session: session) }

  let(:print_host) { build(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100") }
  let(:session) { instance_double(Print::SdcpService::WebsocketSession) }

  describe "ADR D-1 SDCP timeout seam (INIT-009/SPEC-002)" do
    it "keeps UI WS timeout strictly below control WS timeout" do
      expect(described_class::SDCP_UI_WS_TIMEOUT).to be <= 3
      expect(described_class::SDCP_CONTROL_WS_TIMEOUT).to eq(10)
      expect(described_class::SDCP_UI_WS_TIMEOUT).to be < described_class::SDCP_CONTROL_WS_TIMEOUT
    end

    it "lists Errno::ETIMEDOUT in TRANSPORT_ERRORS (Socket.tcp connect_timeout)" do
      expect(described_class::TRANSPORT_ERRORS).to include(Errno::ETIMEDOUT)
    end

    # rubocop:disable RSpec/ExampleLength -- dual-session seam needs both budgets asserted
    it "builds a UI-budget session for status and a control-budget session for pause" do
      host = build(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100")
      svc = described_class.new(print_host: host)
      ui_session = instance_double(Print::SdcpService::WebsocketSession)
      control_session = instance_double(Print::SdcpService::WebsocketSession)

      allow(Print::SdcpService::WebsocketSession).to receive(:new)
        .with(hash_including(timeout: described_class::SDCP_UI_WS_TIMEOUT))
        .and_return(ui_session)
      allow(Print::SdcpService::WebsocketSession).to receive(:new)
        .with(hash_including(timeout: described_class::SDCP_CONTROL_WS_TIMEOUT))
        .and_return(control_session)
      allow(ui_session).to receive(:call).with(hash_including(cmd: 0)).and_return({"Ack" => 0})
      allow(control_session).to receive(:call).with(hash_including(cmd: 129)).and_return({"Ack" => 0})

      svc.status
      svc.pause_print

      expect(Print::SdcpService::WebsocketSession).to have_received(:new)
        .with(hash_including(timeout: described_class::SDCP_UI_WS_TIMEOUT))
      expect(Print::SdcpService::WebsocketSession).to have_received(:new)
        .with(hash_including(timeout: described_class::SDCP_CONTROL_WS_TIMEOUT))
      expect(ui_session).to have_received(:call).with(hash_including(cmd: 0))
      expect(control_session).to have_received(:call).with(hash_including(cmd: 129))
    end

    it "uses the UI status path when normalized_status fetches live status" do
      host = build(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100")
      svc = described_class.new(print_host: host)
      ui_session = instance_double(Print::SdcpService::WebsocketSession)
      allow(Print::SdcpService::WebsocketSession).to receive(:new)
        .with(hash_including(timeout: described_class::SDCP_UI_WS_TIMEOUT))
        .and_return(ui_session)
      allow(ui_session).to receive(:call).with(hash_including(cmd: 0)).and_return({
        "Ack" => 0,
        "Status" => {"CurrentStatus" => [0], "PrintInfo" => {}}
      })

      expect(svc.normalized_status[:machine_status]).to eq([0])
      expect(ui_session).to have_received(:call).with(hash_including(cmd: 0))
    end
    # rubocop:enable RSpec/ExampleLength
  end

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
      response = instance_double(Net::HTTPSuccess, code: "200", body: {code: "000000", success: true, data: {}}.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:request).and_return(response)
      allow(session).to receive(:call).with(hash_including(cmd: 128)).and_return({"Ack" => 0})

      result = service.upload(io: StringIO.new("ctb-bytes"), filename: "part.ctb", start: true)
      expect(result[:filename]).to eq("part.ctb")
      expect(result[:bytes]).to eq(9)
      expect(session).to have_received(:call).with(hash_including(cmd: 128))
    end

    it "refuses upload when free space is known and insufficient (REQ-005)" do
      host = build(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100",
        storage_bytes_used: 900, storage_bytes_total: 1000)
      tight = described_class.new(print_host: host, session: session)
      expect {
        tight.upload(io: StringIO.new("x" * 200), filename: "part.ctb")
      }.to raise_error(Print::SdcpService::Error, /insufficient on-printer storage/)
    end
  end

  describe "#list_files / #delete_files" do
    it "lists via Cmd 258" do
      allow(session).to receive(:call)
        .with(hash_including(cmd: 258, data: {"Url" => "/local"}))
        .and_return({"Ack" => 0, "FileList" => [{"name" => "/local/a.ctb", "type" => 1, "usedSize" => 10, "totalSize" => 100}]})
      files = service.list_files
      expect(files.first[:name]).to eq("/local/a.ctb")
      expect(files.first[:type]).to eq(1)
    end

    it "deletes via Cmd 259" do
      allow(session).to receive(:call)
        .with(hash_including(cmd: 259, data: hash_including("FileList" => ["/local/a.ctb"])))
        .and_return({"Ack" => 0})
      expect(service.delete_files(file_list: ["/local/a.ctb"])).to include("Ack" => 0)
    end
  end

  describe "#normalized_status" do
    it "maps layer / eta / temps from status payload" do
      raw = {
        "Status" => {
          "CurrentStatus" => [1],
          "TempOfUVLED" => 42.5,
          "TempOfBox" => 30.0,
          "ReleaseFilm" => 120,
          "PrintScreen" => 7200,
          "PrintInfo" => {
            "Status" => 3,
            "CurrentLayer" => 100,
            "TotalLayer" => 1000,
            "CurrentTicks" => 60_000,
            "TotalTicks" => 360_000,
            "Filename" => "part.ctb"
          }
        }
      }
      dto = service.normalized_status(raw)
      expect(dto[:current_layer]).to eq(100)
      expect(dto[:total_layers]).to eq(1000)
      expect(dto[:eta_seconds]).to eq(300)
      expect(dto[:temp_uv_c]).to eq(42.5)
      expect(dto[:fep_cycles]).to eq(120)
      expect(dto[:lcd_seconds]).to eq(7200)
    end
  end

  describe "#refresh_maintenance_counters!" do
    it "persists FEP/LCD from status when available" do
      host = create(:print_host, endpoint: "http://10.0.0.199:3030", mainboard_id: "d307202d8c1e0100")
      svc = described_class.new(print_host: host, session: session)
      allow(session).to receive(:call).with(hash_including(cmd: 0)).and_return({
        "Ack" => 0,
        "Status" => {"ReleaseFilm" => 55, "PrintScreen" => 7200}
      })
      svc.refresh_maintenance_counters!
      expect(host.reload.fep_cycles).to eq(55)
      expect(host.lcd_hours).to eq(2)
    end
  end

  describe ".parse_discover_payload" do
    it "extracts JSON after M99999 prefix" do
      raw = 'M99999{"BrandName":"UniFormation","MainboardID":"d307202d8c1e0100"}'
      expect(described_class.parse_discover_payload(raw)["BrandName"]).to eq("UniFormation")
    end
  end

  describe ".normalize_discover_candidate" do
    it "builds a non-persisted candidate with machine_model and endpoint" do
      parsed = {
        "BrandName" => "UniFormation",
        "MachineName" => "GK3 Pro",
        "MainboardID" => "d307202d8c1e0100",
        "MainboardIP" => "10.0.0.199",
        "FirmwareVersion" => "1.2.3"
      }
      candidate = described_class.normalize_discover_candidate(parsed)
      expect(candidate[:brand]).to eq("UniFormation")
      expect(candidate[:machine_model]).to eq("GK3 Pro")
      expect(candidate[:endpoint]).to eq("http://10.0.0.199:3030")
      expect(candidate[:mainboard_id]).to eq("d307202d8c1e0100")
      expect(PrintHost.where(mainboard_id: "d307202d8c1e0100")).to be_empty
    end

    it "reads identity from nested Data (GK3 discover payload)" do
      parsed = {
        "Id" => "x",
        "Data" => {
          "BrandName" => "UniFormation",
          "MachineName" => "GK3 Pro",
          "MainboardID" => "d307202d8c1e0100",
          "MainboardIP" => "10.0.0.199",
          "FirmwareVersion" => "V1.0"
        }
      }
      candidate = described_class.normalize_discover_candidate(parsed)
      expect(candidate[:brand]).to eq("UniFormation")
      expect(candidate[:mainboard_id]).to eq("d307202d8c1e0100")
      expect(candidate[:endpoint]).to eq("http://10.0.0.199:3030")
    end
  end

  describe "#control_port" do
    it "uses 3030 when endpoint omits a port (URI default 80)" do
      host = build(:print_host, endpoint: "http://10.0.0.199")
      svc = described_class.new(print_host: host)
      expect(svc.send(:control_port)).to eq(3030)
      expect(svc.send(:websocket_url)).to eq("ws://10.0.0.199:3030/websocket")
    end

    it "keeps an explicit non-default port" do
      host = build(:print_host, endpoint: "http://10.0.0.199:3031")
      svc = described_class.new(print_host: host)
      expect(svc.send(:control_port)).to eq(3031)
    end
  end

  describe ".discover_candidates allowlist" do
    it "raises when all targets are public" do
      expect {
        described_class.discover_candidates(hosts: ["1.1.1.1"], timeout: 0.1)
      }.to raise_error(Print::SdcpService::Error, /allowlisted/)
    end

    it "strips path components from upload filenames" do
      response = instance_double(Net::HTTPSuccess, code: "200", body: {code: "000000", success: true, data: {}}.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:request).and_return(response)

      result = service.upload(io: StringIO.new("ctb-bytes"), filename: "../../evil.ctb")
      expect(result[:filename]).to eq("evil.ctb")
    end

    it "rejects storage deletes outside /local" do
      expect {
        service.delete_files(file_list: ["/etc/passwd"])
      }.to raise_error(Print::SdcpService::Error, /under \/local/)
    end
  end
end
