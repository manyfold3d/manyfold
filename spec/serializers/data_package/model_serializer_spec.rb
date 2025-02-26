require "rails_helper"

RSpec.describe DataPackage::ModelSerializer do
  context "when generating an Data Package representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) {
      m = create(:model, :with_tags, name: "Test Model", creator: create(:creator))
      image = create(:model_file, filename: "image.png", model: m)
      m.preview_file = image
      create(:model_file, filename: "model.stl", model: m)
      m
    }

    it "includes name" do
      expect(output[:name]).to eq "test-model"
    end

    it "includes title" do
      expect(output[:title]).to eq "Test Model"
    end

    it "includes caption and notes in description" do
      expect(output[:description]).to eq "#{object.caption}

#{object.notes}"
    end

    it "includes just caption if there's no notes" do
      object.notes = nil
      expect(output[:description]).to eq object.caption
    end

    it "includes just notes if there's no caption" do
      object.caption = nil
      expect(output[:description]).to eq object.notes
    end

    it "includes homepage" do
      expect(output[:homepage]).to eq "http://localhost:3214/models/#{object.to_param}"
    end

    it "includes image if preview is set to an image" do
      expect(output[:image]).to eq "image.png"
    end

    it "does not include image if preview is missing" do
      object.preview_file = nil
      expect(output[:image]).to be_nil
    end

    it "does not include image if preview is a 3d model" do
      object.preview_file = object.model_files.find_by(filename: "model.stl")
      expect(output[:image]).to be_nil
    end

    it "includes tags in keywords" do
      expect(output[:keywords]).to eq [
        "Tag #0",
        "Tag #1"
      ]
    end

    it "includes license" do
      expect(output[:licenses][0]).to eq({
        name: "MIT",
        path: "https://spdx.org/licenses/MIT.html"
      })
    end

    it "supports commercial license with no path" do
      object.license = "LicenseRef-Commercial"
      expect(output[:licenses][0]).to eq({
        name: "LicenseRef-Commercial"
      })
    end

    it "works with no license" do
      object.license = nil
      expect(output[:licenses]).to be_nil
    end

    it "includes resources" do
      expect(output[:resources]).not_to be_empty
    end

    it "includes valid resource data" do
      expect(output[:resources][0]).to have_key(:path)
    end

    it "includes valid contributor data" do
      expect(output[:contributors][0]).to have_key(:title)
    end

    it "does not include contributors if there is no creator" do
      object.creator = nil
      expect(output[:contributors]).to be_nil
    end
  end
end
