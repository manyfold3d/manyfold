require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::AnalyseModelFileJob do
  it "calculates file digest if not set" do
    file = create(:model_file, filename: "test.obj", digest: nil, size: 10)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    allow(file).to receive(:calculate_digest).once.and_return("deadbeef")
    allow(ModelFile).to receive(:find).with(file.id).and_return(file)
    described_class.perform_now file.id
    file.reload
    expect(file.digest).to eq "deadbeef"
  end

  it "calculates file size if not set" do
    file = create(:model_file, filename: "test.obj", digest: "deadbeef", size: nil)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    allow(File).to receive(:size).once.and_return(1234)
    described_class.perform_now file.id
    file.reload
    expect(file.size).to eq 1234
  end

  it "detects ASCII STL files and creates a Problem record" do
    file = create(:model_file, filename: "test.stl", digest: "deadbeef", size: 1234)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    allow(File).to receive(:read).with(file.pathname, 6).once.and_return("solid ")
    expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inefficient"
    expect(Problem.first.note).to eq "ASCII STL"
  end

  it "detects Wavefront OBJ files and creates a Problem record" do
    file = create(:model_file, filename: "test.obj", digest: "deadbeef", size: 1234)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inefficient"
    expect(Problem.first.note).to eq "Wavefront OBJ"
  end

  it "detects ASCII PLY files and creates a Problem record" do
    file = create(:model_file, filename: "test.ply", digest: "deadbeef", size: 1234)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    allow(File).to receive(:read).with(file.pathname, 16).once.and_return("ply\rformat ascii")
    expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inefficient"
    expect(Problem.first.note).to eq "ASCII PLY"
  end

  it "detects duplicate files and creates a Problem record" do
    file = create(:model_file, filename: "test.stl", digest: "deadbeef", size: 1234)
    allow(file).to receive(:duplicate?).once.and_return(true)
    allow(ModelFile).to receive(:find).with(file.id).and_return(file)
    allow(File).to receive(:exist?).with(file.pathname).and_return(true)
    allow(File).to receive(:read).and_return("whatever")
    expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "duplicate"
  end
end
