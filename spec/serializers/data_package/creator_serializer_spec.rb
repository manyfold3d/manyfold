require "rails_helper"

RSpec.describe DataPackage::CreatorSerializer do
  context "when generating an Data Package representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) { create(:creator) }

    it "includes name" do
      expect(output[:title]).to eq object.name
    end

    it "includes creator role" do
      expect(output[:roles][0]).to eq "creator"
    end

    it "includes path" do
      expect(output[:path]).to eq "http://localhost:3214/creators/#{object.to_param}"
    end
  end
end
