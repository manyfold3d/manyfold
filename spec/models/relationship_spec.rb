require "rails_helper"

RSpec.describe Relationship do
  context "when creating relationships between files" do
    let(:model) { create(:model) }
    let(:first) { create(:model_file, model: model) }
    let(:second) { create(:model_file, model: model) }

    it "creates valid objects" do
      relationship = described_class.create(subject: first, objekt: second, predicate: "supported")
      expect(relationship).to be_valid
    end

    it "cannot duplicate objects" do
      described_class.create(subject: first, objekt: second, predicate: "supported")
      relationship = described_class.create(subject: first, objekt: second, predicate: "supported")
      expect(relationship).not_to be_valid
    end
  end

  it "can create relationships between models" do
    model1 = create(:model)
    model2 = create(:model)
    relationship = described_class.create(subject: model1, objekt: model2, predicate: "remixed")
    expect(relationship).to be_valid
  end

  it "can create relationships between models and links" do
    model = create(:model)
    link = create(:link, linkable: model)
    relationship = described_class.create(subject: model, objekt: link, predicate: "remixed")
    expect(relationship).to be_valid
  end
end
