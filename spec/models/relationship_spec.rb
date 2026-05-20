require "rails_helper"

RSpec.describe Relationship do
  context "when creating relationships between files" do
    let(:model) { create(:model) }
    let(:first) { create(:model_file, model: model) }
    let(:second) { create(:model_file, model: model) }

    it "creates valid objects" do
      relationship = described_class.create(subject: first, objekt: second, predicate: "supported_version_of")
      expect(relationship).to be_valid
    end

    it "must use known predicates" do
      relationship = described_class.create(subject: first, objekt: second, predicate: "invalid_predicate_for")
      expect(relationship).not_to be_valid
    end

    it "cannot duplicate objects" do
      described_class.create(subject: first, objekt: second, predicate: "supported_version_of")
      relationship = described_class.create(subject: first, objekt: second, predicate: "supported_version_of")
      expect(relationship).not_to be_valid
    end
  end

  context "when creating relationships between models" do
    let(:first) { create(:model) }
    let(:second) { create(:model) }

    it "creates valid objects" do
      relationship = described_class.create(subject: first, objekt: second, predicate: "adapted_from")
      expect(relationship).to be_valid
    end
  end

  context "when creating relationships between models and links" do
    let(:model) { create(:model) }
    let(:link) { create(:link, linkable: model) }

    it "creates valid objects" do
      relationship = described_class.create(subject: model, objekt: link, predicate: "adapted_from")
      expect(relationship).to be_valid
    end
  end
end
