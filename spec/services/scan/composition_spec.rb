# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scan::Composition do
  def pack(path, meshes:, name: path, images: [], supports: [])
    described_class.pack_snapshot(path, name: name, meshes: meshes, images: images, supports: supports)
  end

  it "classifies identical mesh-id sets as same_pack" do
    a = pack("A", meshes: %w[a.stl|1 b.stl|1 c.stl|1])
    b = pack("B", meshes: %w[a.stl|1 b.stl|1 c.stl|1])
    d = described_class.decide(a, b)
    expect(d.verdict).to eq("same_pack")
    expect(d.eligible_to_merge).to be true
  end

  it "classifies A subset of B as subset with keeper B" do
    a = pack("A", meshes: %w[a.stl|1 b.stl|1])
    b = pack("B", meshes: %w[a.stl|1 b.stl|1 extra.stl|1])
    d = described_class.decide(a, b)
    expect(d.verdict).to eq("subset")
    expect(d.keeper_path).to eq("B")
    expect(d.eligible_to_merge).to be true
  end

  it "refuses commons when uniques on each side meet the cap" do
    a = pack("A", meshes: %w[shared.stl|1 a1.stl|1 a2.stl|1 a3.stl|1])
    b = pack("B", meshes: %w[shared.stl|1 b1.stl|1 b2.stl|1 b3.stl|1])
    d = described_class.decide(a, b)
    expect(d.verdict).to eq("commons")
    expect(d.eligible_to_merge).to be false
  end

  it "refuses image_only when only previews overlap" do
    a = pack("A", meshes: [], images: %w[preview.jpg])
    b = pack("B", meshes: [], images: %w[preview.jpg])
    d = described_class.decide(a, b)
    expect(d.verdict).to eq("image_only")
    expect(d.eligible_to_merge).to be false
  end

  it "refuses presupport_variant instead of subset when extras are supports" do
    a = pack("A", meshes: %w[core.stl|1])
    b = pack("B", meshes: %w[core.stl|1 support_leg.stl|1])
    d = described_class.decide(a, b)
    expect(d.verdict).to eq("presupport_variant")
    expect(d.eligible_to_merge).to be false
  end

  it "allows eligible_to_merge only for same_pack and subset" do
    expect(described_class::ELIGIBLE_VERDICTS).to contain_exactly("same_pack", "subset")
  end
end
