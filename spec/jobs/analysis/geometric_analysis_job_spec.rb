require "rails_helper"
require "support/mock_directory"

RSpec.describe Analysis::GeometricAnalysisJob do
  let(:file) { create(:model_file, filename: "test.stl") }
  let(:mesh) do
    m = Mittsu::Mesh.new(Mittsu::SphereGeometry.new(2.0, 32, 16))
    m.geometry.merge_vertices
    m
  end

  before do
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    allow(ModelFile).to receive(:find).and_call_original
    allow(ModelFile).to receive(:find).with(file.id).and_return(file)
    allow(SiteSettings).to receive(:analyse_manifold).and_return(true)
  end

  it "does not create Problems for a good mesh" do
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    expect { described_class.perform_now(file.id) }.not_to change(Problem, :count)
  end

  it "creates a Problem for a non-manifold mesh" do # rubocop:todo RSpec/MultipleExpectations
    allow(mesh).to receive(:manifold?).and_return(false)
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    expect { described_class.perform_now(file.id) }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "non_manifold"
  end

  it "removes a manifold problem if the mesh is OK" do
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    create(:problem, problematic: file, category: :non_manifold)
    expect { described_class.perform_now(file.id) }.to change(Problem, :count).from(1).to(0)
  end

  it "creates a Problem for an inside-out mesh" do # rubocop:todo RSpec/MultipleExpectations
    pending "not currently working reliably"
    allow(mesh).to receive(:solid?).and_return(false)
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    expect { described_class.perform_now(file.id) }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inside_out"
  end

  it "removes an inside-out problem if the mesh is OK" do
    pending "not currently working reliably"
    allow(described_class).to receive(:load_mesh).with(file).and_return(mesh)
    create(:problem, problematic: file, category: :inside_out)
    expect { described_class.perform_now(file.id) }.to change(Problem, :count).from(1).to(0)
  end

  it "raises exception if file ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
