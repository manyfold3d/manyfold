require "rails_helper"

RSpec.describe Print::OctoprintService, :after_first_run, :vcr do
  subject(:service) {
    described_class.new(
    print_host: create(:print_host,
      protocol: "octoprint",
      name: "Octoprint",
      endpoint: endpoint,
      credentials: credentials)
  )
  }

  let(:endpoint) { ENV.fetch("OCTOPRINT_ENDPOINT", "http://octoprint.example.com") }
  let(:credentials) { ENV.fetch("OCTOPRINT_API_KEY", "fake_api_key") }
  let(:file) { create(:model_file, filename: "test.gcode") }

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    VCR.configure do |c|
      c.filter_sensitive_data("<OCTOPRINT_API_KEY>") { credentials }
      c.filter_sensitive_data("<OCTOPRINT_ENDPOINT>") { endpoint }
    end
  end

  context "with good connection details" do
    it "verifies connection" do
      expect(service.ok?).to be true
    end

    it "uploads a file" do
      expect(service.upload(file: file, start_print: true)).to be true
    end
  end

  context "with bad API key" do
    let(:credentials) { "bad_api_key" }

    it "flags connection error" do
      expect(service.ok?).to be false
    end

    it "doesn't upload file" do
      expect { service.upload(file: file, start_print: true) }.to raise_error(PrintHost::NotReady)
    end
  end

  context "with bad endpoint" do
    let(:endpoint) { "not-a-url" }

    it "flags connection error" do
      expect(service.ok?).to be false
    end

    it "doesn't upload file" do
      expect { service.upload(file: file, start_print: true) }.to raise_error(PrintHost::NotReady)
    end
  end
end
