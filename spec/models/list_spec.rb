require "rails_helper"

RSpec.describe List do
  it_behaves_like "Caber::Object"

  it "has a name" do
    list = described_class.build(name: "My Favourites")
    expect(list.name).to eq "My Favourites"
  end

  it "requires a name" do
    expect(described_class.build(name: nil)).not_to be_valid
  end

  it "ensures name isn't too long" do
    expect(described_class.build(name: SecureRandom.alphanumeric(256))).not_to be_valid
  end

  context "with an existing list" do
    subject(:list) { described_class.create(name: "My Favourites") }

    it "can add models" do
      expect { list.models << create(:model) }.to change { list.models.count }.from(0).to(1)
    end

    it "creates ListItems" do
      expect { list.models << create(:model) }.to change(ListItem, :count).from(0).to(1)
    end

    it "destroys ListItems when removed" do
      list.models << create(:model)
      expect { list.destroy }.to change(ListItem, :count).from(1).to(0)
    end

    it "doesn't destroy listed models when removed" do
      list.models << create(:model)
      expect { list.destroy }.not_to change(Model, :count)
    end
  end
end
