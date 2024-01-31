require "rails_helper"

RSpec.describe Problem do
  describe "querying visible scope" do
    let(:settings) do
      {
        missing: :silent,
        empty: :info,
        nesting: :warning,
        inefficient: :info,
        duplicate: :warning
      }
    end

    before do
      create_list(:problem, 3, :missing)
      create_list(:problem, 3, :inefficient)
    end

    it "lists visible problems" do
      expect(described_class.visible(settings).length).to eq 3
      expect(described_class.visible(settings).map { |x| x.category.to_sym }).to include :inefficient
    end

    it "does not include silenced problems" do
      expect(described_class.visible(settings).map { |x| x.category.to_sym }).not_to include :missing
    end
  end

  context "when being ignored" do
    it "have an ignored flag" do
      p = build(:problem)
      expect(p).to respond_to(:ignored)
    end
  end
end
