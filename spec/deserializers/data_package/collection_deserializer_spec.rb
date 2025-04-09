require "rails_helper"

RSpec.describe DataPackage::CollectionDeserializer do
  context "when parsing a Data Package" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }

    context "with a valid collection linked to this server" do
      let(:collection) { create(:collection) }
      let(:object) do
        {
          "title" => collection.name,
          "path" => "http://localhost:3214/collections/#{collection.to_param}",
          "caption" => "caption goes here",
          "description" => "description goes here",
          "links" => [
            {
              "path" => "http://example.com"
            }
          ]
        }
      end

      it "parses name" do
        expect(output[:name]).to eq collection.name
      end

      it "matches collection ID" do
        expect(output[:id]).to eq collection.id
      end

      it "does not add main detected path as link" do
        expect(output[:links_attributes]).not_to include({url: "http://localhost:3214/collections/#{collection.to_param}"})
      end

      it "parses links" do
        expect(output[:links_attributes]).to include({url: "http://example.com"})
      end

      it "parses notes" do
        expect(output[:notes]).to eq "description goes here"
      end

      it "parses caption" do
        expect(output[:caption]).to eq "caption goes here"
      end
    end

    context "with a valid collection hosted elsewhere" do
      let(:object) do
        {
          "title" => "Bruce Wayne",
          "path" => "http://example.com/bruce-wayne",
          "roles" => ["collection"]
        }
      end

      it "parses name" do
        expect(output[:name]).to eq "Bruce Wayne"
      end

      it "includes main path as link" do
        expect(output[:links_attributes]).to include({
          url: "http://example.com/bruce-wayne"
        })
      end
    end
  end
end
