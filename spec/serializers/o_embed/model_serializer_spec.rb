require "rails_helper"

RSpec.describe OEmbed::ModelSerializer do
  context "when generating oEmbed representation" do
    subject(:serializer) { described_class.new(model) }

    let(:result) { serializer.serialize }

    context "when serializing the basics" do
      let(:model) { create(:model, :public) }

      it_behaves_like "GenericOEmbedSerializer"

      it "includes model name" do
        expect(result[:title]).to eq model.name
      end
    end

    context "when serializing creator info" do
      let(:creator) { create(:creator, :public) }
      let(:model) { create(:model, :public, creator: creator) }

      it "includes creator name" do
        expect(result[:author_name]).to eq creator.name
      end

      it "includes creator link" do
        expect(result[:author_url]).to eq "http://localhost:3214/creators/#{creator.to_param}"
      end
    end

    context "when showing a model with an image preview" do
      let(:model) {
        m = create(:model, :public, :with_tags)
        m.preview_file = create(:model_file, filename: "image.png", model: m)
        m
      }

      it "has photo type" do
        expect(result[:type]).to eq "photo"
      end

      it "includes image url" do
        expect(result[:url]).to eq "http://localhost:3214/models/#{model.to_param}/model_files/#{model.preview_file.to_param}.png"
      end
    end

    context "when showing a model with an video preview" do
      let(:model) {
        m = create(:model, :public, :with_tags)
        m.preview_file = create(:model_file, filename: "video.mp4", model: m)
        m
      }

      it "has video type" do
        expect(result[:type]).to eq "video"
      end

      it "generates HTML video tag" do
        expect(result[:html]).to start_with "<video"
      end
    end

    context "when showing a model with a 3d preview" do
      let(:model) {
        m = create(:model, :public, :with_tags)
        m.preview_file = create(:model_file, filename: "model.stl", model: m)
        m
      }

      it "has rich type" do
        expect(result[:type]).to eq "rich"
      end

      it "generates HTML iframe tag" do
        expect(result[:html]).to start_with "<iframe"
      end
    end

    context "when showing a model with a PDF preview" do
      let(:model) {
        m = create(:model, :public, :with_tags)
        m.preview_file = create(:model_file, filename: "instructions.pdf", model: m)
        m
      }

      it "has link type" do
        expect(result[:type]).to eq "link"
      end
    end
  end
end
