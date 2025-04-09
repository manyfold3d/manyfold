require "rails_helper"

RSpec.describe OEmbed::CollectionSerializer do
  context "when generating oEmbed representation" do
    subject(:serializer) { described_class.new(collection) }

    let(:result) { serializer.serialize }

    context "when serializing the basics" do
      let(:collection) { create(:collection, :public) }

      it_behaves_like "GenericOEmbedSerializer"

      it "includes collection name" do
        expect(result[:title]).to eq collection.name
      end
    end

    context "when serializing creator info" do
      let(:creator) { create(:creator, :public) }
      let(:collection) { create(:collection, :public, creator: creator) }

      it "includes creator name" do
        expect(result[:author_name]).to eq creator.name
      end

      it "includes creator link" do
        expect(result[:author_url]).to eq "http://localhost:3214/creators/#{creator.to_param}"
      end
    end

    context "when showing a collection with an image preview" do
      let(:model) {
        m = create(:model, :public)
        m.update!(preview_file: create(:model_file, filename: "image.png", model: m))
        m
      }
      let(:collection) {
        c = create(:collection, :public)
        model.update!(collection: c)
        c
      }

      it "has photo type" do
        expect(result[:type]).to eq "photo"
      end

      it "includes image url" do
        expect(result[:url]).to eq "http://localhost:3214/models/#{model.to_param}/model_files/#{model.preview_file.to_param}.png"
      end
    end

    context "when showing a collection with a video preview" do
      let(:model) {
        m = create(:model, :public)
        m.update!(preview_file: create(:model_file, filename: "video.mp4", model: m))
        m
      }
      let(:collection) {
        c = create(:collection, :public)
        model.update!(collection: c)
        c
      }

      it "has video type" do
        expect(result[:type]).to eq "video"
      end

      it "generates HTML video tag" do
        expect(result[:html]).to start_with "<video"
      end
    end

    context "when showing a collection with a 3d preview" do
      let(:model) {
        m = create(:model, :public)
        m.update!(preview_file: create(:model_file, filename: "model.stl", model: m))
        m
      }
      let(:collection) {
        c = create(:collection, :public)
        model.update!(collection: c)
        c
      }

      it "has rich type" do
        expect(result[:type]).to eq "rich"
      end

      it "generates HTML iframe tag" do
        expect(result[:html]).to start_with "<iframe"
      end
    end

    context "when showing a collection with a PDF preview" do
      let(:model) {
        m = create(:model, :public)
        m.update!(preview_file: create(:model_file, filename: "instructions.pdf", model: m))
        m
      }
      let(:collection) {
        c = create(:collection, :public)
        model.update!(collection: c)
        c
      }

      it "has link type" do
        expect(result[:type]).to eq "link"
      end
    end

    context "when showing a collection with no preview" do
      let(:collection) { create(:collection, :public) }

      it "has link type" do
        expect(result[:type]).to eq "link"
      end
    end
  end
end
