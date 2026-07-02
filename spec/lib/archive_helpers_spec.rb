require "rails_helper"

class ArchiveHelpersTestHarness
  include ArchiveHelpers
end

RSpec.describe ArchiveHelpers do
  subject(:harness) { ArchiveHelpersTestHarness.new }

  context "when counting common path prefixes" do
    it "returns zero if there are no directories at all" do
      expect(harness.count_common_elements([])).to eq 0
    end

    it "returns zero if there are no common prefixes" do
      expect(harness.count_common_elements([
        ["folder1"],
        ["folder2"],
        []
      ])).to eq 0
    end

    it "returns the number of common prefixes if present" do
      expect(harness.count_common_elements([
        ["root", "sub", "folder1"],
        ["root", "sub", "folder2"]
      ])).to eq 2
    end

    it "returns correct count where all prefixes are the same" do
      expect(harness.count_common_elements([
        ["root", "sub", "folder"],
        ["root", "sub", "folder"]
      ])).to eq 3
    end

    it "returns correct count where a common folder has a subfolder" do
      expect(harness.count_common_elements([
        ["root", "sub"],
        ["root", "sub", "folder2"]
      ])).to eq 2
    end

    it "returns zero for *some* common prefixes but not on everything" do
      expect(harness.count_common_elements([
        ["folder1", "sub1"],
        ["folder1", "sub2"],
        ["folder2", "sub1"]
      ])).to eq 0
    end
  end
end
