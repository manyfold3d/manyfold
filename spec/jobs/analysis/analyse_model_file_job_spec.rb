require "rails_helper"
require "support/mock_directory"

RSpec.describe Analysis::AnalyseModelFileJob do
  context "with an existing file" do
    let(:file) { create(:model_file, filename: "test.3mf", digest: "deadc0de") }

    before do
      allow(ModelFile).to receive(:find).with(file.id).and_return(file)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).once.and_return(1.day.ago)
      allow(file).to receive(:calculate_digest).once.and_return("deadbeef")
    end

    it "calculates file digest if not set" do
      file.update!(digest: nil)
      expect { described_class.perform_now file.id }.to(
        change(file, :digest).from(nil).to("deadbeef")
      )
    end

    it "doesn't queue geometric analysis if file digest doesn't change" do
      expect { described_class.perform_now file.id }.not_to(
        have_enqueued_job(Analysis::GeometricAnalysisJob)
      )
    end

    it "queues geometric analysis if file digest changes" do
      file.update(digest: nil) # force analysis
      expect { described_class.perform_now file.id }.to(
        have_enqueued_job(Analysis::GeometricAnalysisJob).with(file.id).once
      )
    end

    it "detects ASCII STL files and creates a Problem record" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      allow(file).to receive_messages(extension: "stl", size: 1234)
      allow(file).to receive(:head).with(6).once.and_return("solid ")
      expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
      expect(Problem.first.category).to eq "inefficient"
      expect(Problem.first.note).to eq "ASCII STL"
    end

    it "detects Wavefront OBJ files and creates a Problem record" do # rubocop:todo RSpec/MultipleExpectations
      allow(file).to receive_messages(extension: "obj", size: 1234)
      expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
      expect(Problem.first.category).to eq "inefficient"
      expect(Problem.first.note).to eq "Wavefront OBJ"
    end

    it "detects ASCII PLY files and creates a Problem record" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      allow(file).to receive_messages(extension: "ply", size: 1234)
      allow(file).to receive(:head).with(16).once.and_return("ply\rformat ascii")
      expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
      expect(Problem.first.category).to eq "inefficient"
      expect(Problem.first.note).to eq "ASCII PLY"
    end

    it "detects duplicate files and creates a Problem record" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      allow(file).to receive_messages(size: 1234)
      allow(file).to receive(:duplicate?).once.and_return(true)
      expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
      expect(Problem.first.category).to eq "duplicate"
    end

    it "detects zero-length files and creates a Problem record" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      allow(file).to receive_messages(size: 0)
      expect { described_class.perform_now file.id }.to change(Problem, :count).from(0).to(1)
      expect(Problem.first.category).to eq "empty"
    end
  end

  context "when matching supported/unsupported files" do
    let(:model) { create(:model) }

    [
      %w[model.stl model_supported.stl],
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
      ["Beefy Arm B.stl", "Beefy Arm B Supported.stl",
        ["Beefy Arm A Supported.lys", "Beefy Arm A Supported.stl", "Beefy Arm B Supported.lys"]]
    ].each do |filename, correct, incorrect|
      it "matches #{filename} with #{correct} rather than incorrect options" do # rubocop:todo RSpec/ExampleLength
        incorrect.each do |it|
          create(:model_file, model: model, filename: it, presupported: true)
        end
        unsup = create(:model_file, model: model, filename: filename)
        sup = create(:model_file, model: model, filename: correct, presupported: true)
        described_class.new.match_with_supported_file unsup
        expect(unsup.presupported_version).to eq sup
      end
    end

    it "only matches to same file format" do
      unsup = create(:model_file, model: model, filename: "Beefy Arm R.stl")
      sup = create(:model_file, model: model, filename: "Befy Arm R Supported.stl", presupported: true)
      create(:model_file, model: model, filename: "Beefy Arm R Supported.lys", presupported: true)
      described_class.new.match_with_supported_file unsup
      expect(unsup.presupported_version).to eq sup
    end
  end

  it "raises exception if file ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
