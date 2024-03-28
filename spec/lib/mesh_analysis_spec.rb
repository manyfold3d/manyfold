require "rails_helper"

RSpec.describe "MeshAnalysis" do

  it "verifies that meshes are manifold (i.e. do not have holes)" do
    geometry = Mittsu::SphereGeometry.new(2.0, 32, 16)
    expect(geometry.manifold?).to be true
  end

  it "detects meshes that are non-manifold (i.e. do have holes)" do
    geometry = Mittsu::PlaneBufferGeometry.new(1.0, 1.0)
    expect(geometry.manifold?).to be false
  end

end
