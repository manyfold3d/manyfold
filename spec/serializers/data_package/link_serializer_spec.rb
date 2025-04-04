require "rails_helper"

RSpec.describe DataPackage::LinkSerializer do
  context "when generating an Data Package representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) { create(:link, linkable: create(:model)) }

    it "includes path" do
      expect(output[:path]).to eq object.url
    end
  end
end
