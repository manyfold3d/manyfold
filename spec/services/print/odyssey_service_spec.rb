require "rails_helper"

RSpec.describe Print::OdysseyService, :after_first_run, :vcr do
  subject(:service) {
    described_class.new(
    print_host: create(:print_host,
      protocol: "odyssey",
      name: "Odyssey",
      endpoint: endpoint)
  )
  }

  let(:endpoint) { ENV.fetch("ODYSSEY_ENDPOINT", "http://odyssey.printer.local:12357") }
  let(:file) { create(:model_file, filename: "test.sl1") }

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    VCR.configure do |c|
      c.filter_sensitive_data("<ODYSSEY_ENDPOINT>") { endpoint }
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
