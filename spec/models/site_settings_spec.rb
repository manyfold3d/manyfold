require "rails_helper"

RSpec.describe SiteSettings do
  context "when detecting ignored files" do
    it "accepts normal files" do
      expect(described_class.send(:ignored_file?, "test.stl")).to be false
    end

    it "accepts normal files in subfolders" do
      expect(described_class.send(:ignored_file?, "test/test.stl")).to be false
    end

    it "rejects hidden files" do
      expect(described_class.send(:ignored_file?, ".test.stl")).to be true
    end

    it "rejects hidden files in subfolders" do
      expect(described_class.send(:ignored_file?, "test/.test.stl")).to be true
    end

    it "rejects normal files in hidden subfolders" do
      expect(described_class.send(:ignored_file?, ".test/test.stl")).to be true
    end
  end
end
