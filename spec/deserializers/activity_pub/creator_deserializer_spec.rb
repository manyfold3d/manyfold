require "rails_helper"

RSpec.describe ActivityPub::CreatorDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    let(:actor) { create(:actor, :distant, :f3di_creator) }
    let(:output) { deserializer.create! }

    before do
      # We need a default library in place for avatar images
      create(:library)
    end

    it_behaves_like "GenericDeserializer"

    it "sets creator avatar", :vcr do # rubocop:disable RSpec/ExampleLength
      actor.extensions["icon"] = {
        "type" => "Image",
        "mediaType" => "image/png",
        "url" => "https://avatars.githubusercontent.com/u/152926958?s=200&v=4"
      }
      expect(output.avatar).to be_present
    end

    it "sets creator banner", :vcr do # rubocop:disable RSpec/ExampleLength
      actor.extensions["image"] = {
        "type" => "Image",
        "mediaType" => "image/png",
        "url" => "https://avatars.githubusercontent.com/u/152926958?s=200&v=4"
      }
      expect(output.banner).to be_present
    end
  end
end
