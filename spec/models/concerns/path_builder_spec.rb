require "rails_helper"

RSpec.describe PathBuilder do
  context "when creating path from model metadata" do
    let(:model) {
      create(:model,
        name: "Batarang",
        creator: create(:creator, name: "Bruce Wayne"),
        tag_list: ["bat", "weapon"],
        collection: create(:collection, name: "gadgets"))
    }

    it "includes creator if set" do
      SiteSettings.model_path_template = "{creator}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "bruce-wayne/batarang#1"
    end

    it "includes tags if set" do
      SiteSettings.model_path_template = "{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "bat/weapon/batarang#1"
    end

    it "includes collection if set" do
      SiteSettings.model_path_template = "{collection}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "gadgets/batarang#1"
    end

    it "includes multiple metadata types if set" do
      SiteSettings.model_path_template = "{collection}/{creator}/{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "gadgets/bruce-wayne/bat/weapon/batarang#1"
    end

    it "includes non-token information as literal text" do
      SiteSettings.model_path_template = "{tags}/{creator} - {collection} - {modelName}{modelId}"
      expect(model.formatted_path).to eq "bat/weapon/bruce-wayne - gadgets - batarang#1"
    end

    it "treats unknown tokens as literal text" do
      SiteSettings.model_path_template = "{bad}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "{bad}/batarang#1"
    end
  end

  context "when creating path from missing model metadata" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes creator error if set" do
      SiteSettings.model_path_template = "{creator}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "@unattributed/batarang#1"
    end

    it "handles zero tags" do
      SiteSettings.model_path_template = "{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "@untagged/batarang#1"
    end

    it "includes collection error if set" do
      SiteSettings.model_path_template = "{collection}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "@uncollected/batarang#1"
    end

    it "includes non-token information as literal text" do
      SiteSettings.model_path_template = "{tags}/{creator} - {collection} - {modelName}{modelId}"
      expect(model.formatted_path).to eq "@untagged/@unattributed - @uncollected - batarang#1"
    end
  end

  context "when creating model directory name" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes model ID if option is included" do
      SiteSettings.model_path_template = "{modelName}{modelId}"
      expect(model.formatted_path).to eq "batarang#1"
    end

    it "does not include model ID if option is deselected" do
      SiteSettings.model_path_template = "{modelName}"
      expect(model.formatted_path).to eq "batarang"
    end
  end

  context "when creating folders" do
    let(:model) {
      create(:model,
        name: "Bat-a-rang",
        creator: create(:creator, name: "Bruce Wayne"),
        tag_list: ["bat", "weapon"],
        collection: create(:collection, name: "Wonderful Toys"))
    }

    before do
      SiteSettings.model_path_template = "{creator}/{collection}/{tags}/{modelName}{modelId}"
    end

    it "uses safe names in path if safe_folder_names is set" do
      SiteSettings.safe_folder_names = true
      expect(model.formatted_path).to eq "bruce-wayne/wonderful-toys/bat/weapon/bat-a-rang#1"
    end

    it "uses unmodified names in path names if safe_folder_names is not set" do
      SiteSettings.safe_folder_names = false
      expect(model.formatted_path).to eq "Bruce Wayne/Wonderful Toys/bat/weapon/Bat-a-rang#1"
    end
  end
end
