require "rails_helper"

RSpec.describe ListItem do
  let(:list) { create(:list) }
  let(:model) { create(:model) }

  it "is destroyed if listable is destroyed" do
    list.models << model
    expect { model.destroy }.to change(described_class, :count).from(1).to(0)
  end
end
