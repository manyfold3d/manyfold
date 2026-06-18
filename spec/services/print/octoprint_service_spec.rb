require "rails_helper"

RSpec.describe Print::OctoprintService, :after_first_run, :vcr do
  let(:endpoint) { ENV.fetch("OCTOPRINT_ENDPOINT", "http://octoprint.example.com") }
  let(:credentials) { ENV.fetch("OCTOPRINT_API_KEY", "fake_api_key") }
  let(:print_host) {
    create(:print_host,
      protocol: "octoprint",
      name: "Octoprint",
      endpoint: endpoint,
      credentials: credentials)
  }
  let(:file) { create(:model_file, filename: "test.gcode") }

  before do
    VCR.configure do |c|
      c.filter_sensitive_data("<API_KEY>") { credentials }
      c.filter_sensitive_data("<ENDPOINT>") { endpoint }
    end
  end

  context "with good connection details" do
    it "verifies connection" do
      expect(print_host.service.ok?).to be true
    end

    it "uploads a file" do
      expect(print_host.service.upload(file: file, start_print: true)).to be true
    end
  end

  context "with bad API key" do
    let(:credentials) { "bad_api_key" }

    it "flags connection error" do
      expect(print_host.service.ok?).to be false
    end

    it "doesn't upload file" do
      expect { print_host.service.upload(file: file, start_print: true) }.to raise_error(PrintHost::NotReady)
    end
  end

  context "with bad endpoint" do
    let(:endpoint) { "http://dev.null.local" }

    it "flags connection error" do
      expect(print_host.service.ok?).to be false
    end

    it "doesn't upload file" do
      expect { print_host.service.upload(file: file, start_print: true) }.to raise_error(PrintHost::NotReady)
    end
  end
end
