require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::AnalyseModelFileJob do
  it "calculates file digest if not set" do
    file = create(:model_file, filename: "test.obj", digest: nil, size: 10)
    allow(file).to receive(:calculate_digest).once.and_return("deadbeef")
    described_class.perform_now file
    expect(file.digest).to eq "deadbeef"
  end

  it "calculates file size if not set" do
    file = create(:model_file, filename: "test.obj", digest: "deadbeef", size: nil)
    allow(File).to receive(:size).once.and_return(1234)
    described_class.perform_now file
    expect(file.size).to eq 1234
  end

  it "detects ASCII STL files and creates a Problem record" do
    file = create(:model_file, filename: "test.stl", digest: "deadbeef", size: 1234)
    allow(File).to receive(:read).with(file.pathname, 6).once.and_return("solid ")
    expect { described_class.perform_now file }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inefficient"
    expect(Problem.first.note).to eq "ASCII STL"
    expect(Problem.first.problematic).to eq file
  end
end
