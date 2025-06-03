require "rails_helper"

RSpec.describe ActivityPub::ModelSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) { create(:model, :with_tags, :public, tag_list: []) }

    it_behaves_like "GenericActivityPubSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "3DModel"
    end

    it "includes right number of tags" do
      expect(ap[:tag].count).to eq 2
    end

    it "has valid tag structure" do
      expect(ap[:tag].first).to eq({
        type: "Hashtag",
        name: "Tag #0",
        href: "http://localhost:3214/models?tag=Tag+%230"
      })
    end

    it "includes preview images" do # rubocop:disable RSpec/ExampleLength
      file = create(:model_file, filename: "image.png", model: object)
      object.update!(preview_file: file)
      expect(ap[:preview]).to eq({
        type: "Image",
        mediaType: "image/png",
        url: "http://localhost:3214/models/#{object.to_param}/model_files/#{file.to_param}.png"
      })
    end

    it "includes preview videos" do # rubocop:disable RSpec/ExampleLength
      file = create(:model_file, filename: "video.mp4", model: object)
      object.update!(preview_file: file)
      expect(ap[:preview]).to eq({
        type: "Video",
        mediaType: "video/mp4",
        url: "http://localhost:3214/models/#{object.to_param}/model_files/#{file.to_param}.mp4"
      })
    end

    it "includes preview HTML" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      file = create(:model_file, filename: "image.stl", model: object)
      object.update!(preview_file: file)
      expect(ap[:preview]).to include({
        type: "Document",
        mediaType: "text/html"
      })
      expect(ap[:preview][:content]).to start_with "<iframe"
    end
  end
end
