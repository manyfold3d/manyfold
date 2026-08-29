# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlicedArtifact do
  it "links model, target print_host, format, and estimates" do
    artifact = create(:sliced_artifact,
      format: "jxs",
      estimated_layers: 1000,
      estimated_duration_seconds: 2800,
      estimated_resin_ml: 33.0)
    expect(artifact.model).to be_present
    expect(artifact.print_host).to be_present
    expect(artifact.format).to eq("jxs")
    expect(artifact.estimated_layers).to eq(1000)
    expect(artifact.estimated_duration_seconds).to eq(2800)
    expect(artifact.estimated_resin_ml).to eq(33.0)
  end

  it "requires format" do
    expect(build(:sliced_artifact, format: nil)).not_to be_valid
  end

  it "requires model and print_host" do
    expect(build(:sliced_artifact, model: nil)).not_to be_valid
    expect(build(:sliced_artifact, print_host: nil)).not_to be_valid
  end
end
