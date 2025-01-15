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

    it "lists visible problems" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.visible(settings).length).to eq 3
      expect(described_class.visible(settings).map { |it| it.category.to_sym }).to include :inefficient
    end

    it "does not include silenced problems" do
      expect(described_class.visible(settings).map { |it| it.category.to_sym }).not_to include :missing
    end

    it "falls back to default visibility settings" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.visible({missing: :silent}).length).to eq 3
      expect(described_class.visible({missing: :silent}).map { |it| it.category.to_sym }).to include :inefficient
    end
  end

  context "when being ignored" do
    it "have an ignored flag" do
      p = build(:problem)
      expect(p).to respond_to(:ignored)
    end

    it "leaves out ignored problems by default" do
      create(:problem)
      create(:problem, ignored: true)
      expect(described_class.count).to eq(1)
    end

    it "includes ignored problems when specified" do
      create(:problem)
      create(:problem, ignored: true)
      expect(described_class.unscoped.count).to eq(2)
    end

    it "can ignore an existing problem" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      p = create(:problem)
      expect(p.ignored).to be(false)
      expect(described_class.count).to eq(1)
      p.update!(ignored: true)
      expect(p.ignored).to be(true)
      expect(described_class.count).to eq(0)
    end

    it "can unignore an existing problem" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      p = create(:problem, ignored: true)
      expect(p.ignored).to be(true)
      expect(described_class.count).to eq(0)
      p.update!(ignored: false)
      expect(p.ignored).to be(false)
      expect(described_class.count).to eq(1)
    end
  end

  context "when updating problem state" do
    let(:model) { create(:model, license: nil) }

    it "creates a problem that should exist but doesn't" do
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.to change(described_class, :count).from(0).to(1)
    end

    it "removes a problem that shouldn't exist but does" do
      described_class.create_or_clear model, :no_license, model.license.blank?
      model.update!(license: "CC-BY-4.0")
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.to change(described_class, :count).from(1).to(0)
    end

    it "does nothing with a problem that shouldn't exist and doesn't" do
      model.update!(license: "CC-BY-4.0")
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.not_to change(described_class, :count)
    end

    it "does nothing with a problem that should exist and does" do
      described_class.create_or_clear model, :no_license, model.license.blank?
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.not_to change(described_class, :count)
    end
  end
end
