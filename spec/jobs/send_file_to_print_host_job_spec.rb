# frozen_string_literal: true

require "rails_helper"

RSpec.describe SendFileToPrintHostJob do
  let(:print_host) { create(:print_host) }
  let(:model_file) { instance_double(ModelFile, filename: "part.ctb", attachment: attachment) }
  let(:attachment) { double("attachment") } # rubocop:disable RSpec/VerifiedDoubles
  let(:service) { instance_double(Print::SdcpService) }

  before do
    allow(print_host).to receive(:service).and_return(service)
    allow(attachment).to receive(:open).and_yield(StringIO.new("ctb"))
    allow(service).to receive(:upload)
  end

  it "uploads via SdcpService and starts print" do
    described_class.perform_now(print_host, model_file)
    expect(service).to have_received(:upload).with(
      hash_including(filename: "part.ctb", start: true)
    )
  end
end
