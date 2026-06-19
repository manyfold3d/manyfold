require "rails_helper"

RSpec.describe SendFileToPrintHostJob do
  let(:print_host) { create(:print_host) }
  let(:file) { create(:model_file, filename: "test.gcode") }

  it "raises PrintHost::NotReady if printer is not ok" do
    stub_service = instance_double(Print::MoonrakerService)
    allow(stub_service).to receive(:ok?).and_return(false)
    allow(stub_service).to receive(:upload).and_raise(PrintHost::NotReady)
    allow(print_host).to receive(:service).and_return(stub_service)

    expect { described_class.perform_now(print_host: print_host, file: file) }.to raise_error PrintHost::NotReady
  end

  it "calls upload method in relevant print service" do # rubocop:disable RSpec/ExampleLength
    stub_service = instance_double(Print::MoonrakerService)
    allow(stub_service).to receive(:ok?).and_return(true)
    allow(stub_service).to receive(:upload)
    allow(print_host).to receive(:service).and_return(stub_service)
    described_class.perform_now(print_host: print_host, file: file)
    expect(stub_service).to have_received(:upload).with(file: file, start_print: true).once
  end
end
