require "rails_helper"

RSpec.describe ActivityPub::CollectionSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) { create(:collection, :public) }

    it_behaves_like "GenericActivityPubSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Collection"
    end

    it "includes preview images" do # rubocop:disable RSpec/ExampleLength
      model = create(:model, :public, collection: object)
      file = create(:model_file, filename: "image.png", model: model)
      model.update!(preview_file: file)
      expect(ap[:preview]).to include({
        type: "Image",
        mediaType: "image/png",
        url: "http://localhost:3214/models/#{model.to_param}/model_files/#{file.to_param}.png"
      })
    end

    it "includes preview videos" do # rubocop:disable RSpec/ExampleLength
      model = create(:model, :public, collection: object)
      file = create(:model_file, filename: "video.mp4", model: model)
      model.update!(preview_file: file)
      expect(ap[:preview]).to include({
        type: "Video",
        mediaType: "video/mp4",
        url: "http://localhost:3214/models/#{model.to_param}/model_files/#{file.to_param}.mp4"
      })
    end

    it "includes preview HTML" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      model = create(:model, :public, collection: object)
      file = create(:model_file, filename: "model.stl", model: model)
      model.update!(preview_file: file)
      expect(ap[:preview]).to include({
        type: "Document",
        mediaType: "text/html"
      })
      expect(ap[:preview][:content]).to start_with "<iframe"
    end

    it "includes no preview if there is no public model" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      model = create(:model, collection: object)
      file = create(:model_file, filename: "model.stl", model: model)
      model.update!(preview_file: file)
      expect(ap[:preview]).to be_nil
    end
  end
end
