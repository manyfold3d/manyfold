# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::CompatibilityGate do
  subject(:result) do
    described_class.call(print_host: print_host, stamp: stamp, host_capabilities: host_capabilities)
  end

  let(:print_host) do
    build(:print_host, :with_capabilities,
      native_formats: %w[ctb jxs],
      resolution_w: 7680,
      resolution_h: 4320,
      build_z_mm: 260.0)
  end
  let(:host_capabilities) { {} }
  let(:stamp) { {format: "ctb"} }

  describe "format (REQ-004)" do
    it "passes when format is supported" do
      expect(result.pass?).to be(true)
      expect(result.reasons).to be_empty
    end

    it "fails closed when format is missing" do
      stamp.delete(:format)
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:format_missing)
    end

    it "fails closed when format is unsupported" do
      stamp[:format] = "stl"
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:format_unsupported)
    end

    it "normalizes extension casing and leading dots" do
      stamp[:format] = ".CTB"
      expect(result.pass?).to be(true)
    end
  end

  describe "resolution" do
    it "passes when stamp matches host" do
      stamp.merge!(resolution_w: 7680, resolution_h: 4320)
      expect(result.pass?).to be(true)
    end

    it "fails on mismatch" do
      stamp.merge!(resolution_w: 4096, resolution_h: 2560)
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:resolution_mismatch)
    end

    it "fails when stamp has resolution but host does not" do
      print_host.resolution_w = nil
      print_host.resolution_h = nil
      stamp.merge!(resolution_w: 7680, resolution_h: 4320)
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:resolution_host_unknown)
    end

    it "skips when stamp omits resolution" do
      expect(result.pass?).to be(true)
    end
  end

  describe "Z height" do
    it "passes when within build volume" do
      stamp[:z_height_mm] = 200
      expect(result.pass?).to be(true)
    end

    it "fails when exceeding build Z" do
      stamp[:z_height_mm] = 300
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:z_exceeds_build)
    end

    it "fails when stamp has Z but host build_z is unknown" do
      print_host.build_z_mm = nil
      stamp[:z_height_mm] = 50
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:z_host_unknown)
    end
  end

  describe "AA when present" do
    it "passes when aa is zero" do
      stamp[:aa] = 0
      expect(result.pass?).to be(true)
    end

    it "fails closed when aa required but host aa_max unknown" do
      stamp[:aa] = 4
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:aa_unsupported)
    end

    it "passes when within host aa_max" do
      stamp[:aa] = 4
      host_capabilities[:aa_max] = 8
      expect(result.pass?).to be(true)
    end

    it "fails when exceeding host aa_max" do
      stamp[:aa] = 16
      host_capabilities[:aa_max] = 8
      expect(result.fail?).to be(true)
      expect(result.reasons.map(&:code)).to include(:aa_exceeds_max)
    end
  end
end
