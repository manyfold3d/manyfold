require "rails_helper"

RSpec.describe ManyfoldApi::V0::ModelFileSerializer do
  context "when generating a JSON-LD representation" do
    subject(:serializer) { described_class.new(object, current_user: user) }

    let(:output) { serializer.serialize }
    let(:object) {
      create(:model_file,
        filename: "files/test model.stl",
        presupported: true,
        y_up: true,
        caption: "caption goes here",
        notes: "description goes here")
    }
    let(:user) { nil }

    it "includes name" do
      expect(output[:name]).to eq "Test Model"
    end

    it "includes URL for content" do
      expect(output[:contentUrl]).to eq "http://localhost:3214/models/#{object.model.to_param}/raw/files/test%20model.stl"
    end

    it "does not include write-back URL if user isn't specified" do
      expect(output[:updateContentUrl]).to be_nil
    end

    context "with a user without write permission" do
      let(:user) { create(:user) }

      it "does not include write-back URL" do
        expect(output[:updateContentUrl]).to be_nil
      end
    end

    context "with a user with write permission" do
      let(:user) { create(:user) }

      before do
        object.model.grant_permission_to "edit", user
      end

      it "includes write-back URL" do
        expect(output[:updateContentUrl]).to match(/http:\/\/localhost:3214\/models\/#{object.model.to_param}\/raw\/files\/test%20model\.stl\?sig=[a-zA-Z0-9]*/)
      end
    end

    it "includes notes" do
      expect(output[:description]).to eq "description goes here"
    end

    it "includes caption" do
      expect(output[:caption]).to eq "caption goes here"
    end

    it "includes presupported flag" do
      expect(output[:presupported]).to be true
    end

    it "includes orientation" do
      expect(output[:up]).to eq "+y"
    end
  end
end
