require "rails_helper"
require "support/mock_directory"

RSpec.describe Analysis::GeometricAnalysisJob do
  let(:library) { create(:library, path: Rails.root.join("spec/fixtures")) }
  let(:model) { create(:model, library: library, path: "geometric_analysis_job_spec") }
  let(:manifold_mesh) {
    create(:model_file, model: model, filename: "manifold.stl",
      attachment: ModelFileUploader.upload(File.open("spec/fixtures/geometric_analysis_job_spec/manifold.stl"), :cache))
  }
  let(:non_manifold_mesh) {
    create(:model_file, model: model, filename: "non_manifold.stl",
      attachment: ModelFileUploader.upload(File.open("spec/fixtures/geometric_analysis_job_spec/non_manifold.stl"), :cache))
  }

  before do
    allow(SiteSettings).to receive(:analyse_manifold).and_return(true)
  end

  it "does not create Problems for a good mesh" do
    expect { described_class.perform_now(manifold_mesh.id) }.not_to change(Problem, :count)
  end

  it "creates a Problem for a non-manifold mesh" do # rubocop:todo RSpec/MultipleExpectations
    expect { described_class.perform_now(non_manifold_mesh.id) }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "non_manifold"
  end

  it "removes a manifold problem if the mesh is OK" do
    create(:problem, problematic: manifold_mesh, category: :non_manifold)
    expect { described_class.perform_now(manifold_mesh.id) }.to change(Problem, :count).from(1).to(0)
  end

  it "creates a Problem for an inside-out mesh" do # rubocop:todo RSpec/MultipleExpectations
    pending "not currently working reliably"
    expect { described_class.perform_now(flipped_mesh.id) }.to change(Problem, :count).from(0).to(1)
    expect(Problem.first.category).to eq "inside_out"
  end

  it "removes an inside-out problem if the mesh is OK" do
    pending "not currently working reliably"
    create(:problem, problematic: manifold_mesh, category: :inside_out)
    expect { described_class.perform_now(manifold_mesh.id) }.to change(Problem, :count).from(1).to(0)
  end

  it "raises exception if file ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
