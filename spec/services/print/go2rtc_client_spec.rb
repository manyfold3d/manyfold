# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe Print::Go2rtcClient do
  let(:stream) { "printer-1" }
  let(:frame_url) { "#{described_class.base_url}/api/frame.jpeg?src=#{CGI.escape(stream)}" }
  let(:valid_jpeg) { "\xFF\xD8\xFF" + ("x" * 200) }

  around do |example|
    VCR.turned_off { example.run }
  end

  before do
    WebMock.disable_net_connect!
  end

  describe "ADR D-1 timeout constants (INIT-009/SPEC-002)" do
    it "caps open_timeout at 2s and read_timeout at 3s" do
      expect(described_class::GO2RTC_OPEN_TIMEOUT).to be <= 2
      expect(described_class::GO2RTC_READ_TIMEOUT).to be <= 3
    end
  end

  describe ".frame_jpeg" do
    it "returns the JPEG body on success" do
      stub_request(:get, frame_url).to_return(status: 200, body: valid_jpeg, headers: {"Content-Type" => "image/jpeg"})
      expect(described_class.frame_jpeg(stream: stream)).to eq(valid_jpeg)
    end

    it "raises Error on empty body well under 5s wall" do
      stub_request(:get, frame_url).to_return(status: 200, body: "tiny", headers: {"Content-Type" => "image/jpeg"})
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect { described_class.frame_jpeg(stream: stream) }.to raise_error(described_class::Error, /empty|HTTP/)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      expect(elapsed).to be < 5.0
    end

    it "raises Error on slow/timeout path well under 5s wall" do
      stub_request(:get, frame_url).to_timeout
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect { described_class.frame_jpeg(stream: stream) }.to raise_error(described_class::Error)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      expect(elapsed).to be < 5.0
    end

    it "applies fail-fast open/read timeouts to Net::HTTP" do
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      response = instance_double(Net::HTTPSuccess, code: "200", body: valid_jpeg)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(http).to receive(:get).and_return(response)

      described_class.frame_jpeg(stream: stream)

      expect(http).to have_received(:open_timeout=).with(described_class::GO2RTC_OPEN_TIMEOUT)
      expect(http).to have_received(:read_timeout=).with(described_class::GO2RTC_READ_TIMEOUT)
    end

    it "does not leak the go2rtc base URL in the Error message on empty frame" do
      stub_request(:get, frame_url).to_return(status: 502, body: "", headers: {})
      expect {
        described_class.frame_jpeg(stream: stream)
      }.to raise_error(described_class::Error) { |err|
        expect(err.message).not_to include("go2rtc.manyfold")
        expect(err.message).not_to include(described_class.base_url)
      }
    end
  end
end
