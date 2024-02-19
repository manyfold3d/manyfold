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

  context "when matching supported/unsupported files" do
    let(:model) { create(:model) }

    [
      %w[model.stl model_supported.stl],
      %w[model.stl model_supported.lys],
      %w[model.stl model_sup.stl],
      %w[model.stl SUPPORTED/model.stl],
      %w[unsupported/model.stl supported/model.stl],
      %w[bases_unsupported/model.stl bases_supported/model.stl],
      %w[model.stl supports/model.stl],
      ["no supports/model.stl", "supports/model.stl"],
      %w[model.stl presupported_model.stl],
      ["Beefy Arm R.stl", "Beefy Arm R Supported.stl"],
      ["32mm base 1.stl", "32mm base 1_Supported.stl"]
    ].each do |filename, supported_filename|
      it "matches #{filename} with #{supported_filename}" do
        unsup = create(:model_file, model: model, filename: filename)
        sup = create(:model_file, model: model, filename: supported_filename, presupported: true)
        described_class.new.match_with_supported_file unsup
        expect(unsup.presupported_version).to eq sup
      end
    end

    [
      %w[model_a.stl model_b.stl],
      %w[model.stl model_base.stl],
      %w[model.stl unsupported_model.stl],
      ["Beefy Arm R.stl", "Beefy Arm L Supported.stl"]
    ].each do |filename, supported_filename|
      it "doesn't match #{filename} with #{supported_filename}" do
        unsup = create(:model_file, model: model, filename: filename)
        create(:model_file, model: model, filename: supported_filename, presupported: true)
        described_class.new.match_with_supported_file unsup
        expect(unsup.presupported_version).to be_nil
      end
    end

    [
      ["Beefy Arm R.stl", "Beefy Arm R Supported.stl", "Beefy Arm L Supported.stl"]
    ].each do |filename, correct, incorrect|
      it "matches #{filename} with #{correct} rather than #{incorrect}" do
        unsup = create(:model_file, model: model, filename: filename)
        sup = create(:model_file, model: model, filename: correct, presupported: true)
        create(:model_file, model: model, filename: incorrect, presupported: true)
        described_class.new.match_with_supported_file unsup
        expect(unsup.presupported_version).to eq sup
      end
    end

    it "prefers to match same file format if possible even if the text match is a bit worse" do
      unsup = create(:model_file, model: model, filename: "Beefy Arm R.stl")
      sup = create(:model_file, model: model, filename: "Befy Arm R Supported.stl", presupported: true)
      create(:model_file, model: model, filename: "Beefy Arm R Supported.lys", presupported: true)
      described_class.new.match_with_supported_file unsup
      expect(unsup.presupported_version).to eq sup
    end
  end
end
