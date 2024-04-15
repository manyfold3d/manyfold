require "rails_helper"
require "support/mock_directory"

RSpec.describe Analysis::FileConversionJob do
  around do |ex|
    MockDirectory.create([
      "model_one/files/awesome.stl"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
  let(:model) { create(:model, path: "model_one", library: library) }
  let(:file) { create(:model_file, model: model, filename: "files/awesome.stl") }
  let(:mesh) do
    m = Mittsu::Mesh.new(Mittsu::SphereGeometry.new(2.0, 32, 16))
    m.geometry.merge_vertices
    m
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(file).to receive(:mesh).and_return(mesh)
    allow(ModelFile).to receive(:find).with(file.id).and_return(file)
  end

  context "when converting to 3MF" do
    it "creates a new file" do
      expect { described_class.perform_now(file.id, :threemf) }.to change(ModelFile, :count).from(1).to(2)
    end

    it "creates a file with 3mf extension" do
      described_class.perform_now(file.id, :threemf)
      expect(ModelFile.where.not(id: file.id).first.extension).to eq "3mf"
    end

    it "creates a file with the same basename as the original" do
      described_class.perform_now(file.id, :threemf)
      expect(ModelFile.where.not(id: file.id).first.filename).to eq "files/awesome.3mf"
    end

    it "avoids filenames that already exist" do
      allow(File).to receive(:exist?).with(file.pathname.gsub(".stl", ".3mf")).and_return(true).once
      allow(File).to receive(:exist?).with(file.pathname.gsub(".stl", "-1.3mf")).and_return(true).once
      allow(File).to receive(:exist?).with(file.pathname.gsub(".stl", "-2.3mf")).and_return(false).once
      described_class.perform_now(file.id, :threemf)
      expect(ModelFile.where.not(id: file.id).first.filename).to eq "files/awesome-2.3mf"
    end

    it "creates an actual 3MF file on disk" do
      described_class.perform_now(file.id, :threemf)
      pathname = ModelFile.where.not(id: file.id).first.pathname
      expect(File.exist?(pathname)).to be true
    end

    it "does not remove the original file" do
      described_class.perform_now(file.id, :threemf)
      expect { ModelFile.find(file.id) }.not_to raise_error
    end

    it "should create a file equivalence with the original file"

    it "does not convert non-manifold meshes" do
      allow(mesh).to receive(:manifold?).and_return(false)
      expect { described_class.perform_now(file.id, :threemf) }.not_to change(ModelFile, :count)
    end

    it "queues up analysis job for new file" do
      expect { described_class.perform_now(file.id, :threemf) }.to have_enqueued_job(Analysis::AnalyseModelFileJob)
    end
  end

  it "does nothing with an invalid file ID" do
    allow(ModelFile).to receive(:find).with(nil).and_raise(ActiveRecord::RecordNotFound)
    expect { described_class.perform_now(nil, :threemf) }.not_to raise_error
  end

  it "does nothing with an invalid output format" do
    expect { described_class.perform_now(file.id, :ply) }.not_to raise_error
  end
end
