require "rails_helper"

RSpec.describe OEmbed::CreatorSerializer do
  context "when generating oEmbed representation" do
    subject(:serializer) { described_class.new(creator) }

    let(:result) { serializer.serialize }

    context "when serializing the basics" do
      let(:creator) { create(:creator, :public) }

      it_behaves_like "GenericOEmbedSerializer"

      it "includes Creator name" do
        expect(result[:title]).to eq creator.name
      end

      it "has link type" do
        expect(result[:type]).to eq "link"
      end
    end
  end
end
