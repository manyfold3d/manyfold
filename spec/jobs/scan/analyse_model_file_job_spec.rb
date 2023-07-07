require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::AnalyseModelFileJob do
  it "calculates file digest if not set" do
    file = create(:model_file, digest: nil, size: 10)
    allow(file).to receive(:calculate_digest).once.and_return("deadbeef")
    described_class.perform_now file
    expect(file.digest).to eq "deadbeef"
  end

  it "calculates file size if not set" do
    file = create(:model_file, digest: "deadbeef", size: nil)
    allow(File).to receive(:size).once.and_return(1234)
    described_class.perform_now file
    expect(file.size).to eq 1234
  end
end
