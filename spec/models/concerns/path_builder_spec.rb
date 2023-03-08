require "rails_helper"

RSpec.describe PathBuilder do
  context "when creating path from model metadata" do
    let(:model) {
      create(:model,
        name: "Batarang",
        creator: create(:creator, name: "Bruce Wayne"),
        tag_list: ["bat", "weapon"],
        collection_list: ["gadgets"])
    }

    it "includes creator if set" do
      SiteSettings.model_path_prefix_template = "{creator}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "Bruce Wayne/batarang#1"
    end

    it "includes tags if set" do
      SiteSettings.model_path_prefix_template = "{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "bat/weapon/batarang#1"
    end

    it "includes collection if set" do
      SiteSettings.model_path_prefix_template = "{collection}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "gadgets/batarang#1"
    end

    it "includes multiple metadata types if set" do
      SiteSettings.model_path_prefix_template = "{collection}/{creator}/{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "gadgets/Bruce Wayne/bat/weapon/batarang#1"
    end

    it "includes non-token information as literal text" do
      SiteSettings.model_path_prefix_template = "{tags}/{creator} - {collection} - {modelName}{modelId}"
      expect(model.formatted_path).to eq "bat/weapon/Bruce Wayne - gadgets - batarang#1"
    end

    it "treats unknown tokens as literal text" do
      SiteSettings.model_path_prefix_template = "{bad}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "{bad}/batarang#1"
    end
  end

  context "when creating path from missing model metadata" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes creator error if set" do
      SiteSettings.model_path_prefix_template = "{creator}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "unset-creator/batarang#1"
    end

    it "handles zero tags" do
      SiteSettings.model_path_prefix_template = "{tags}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "@untagged/batarang#1"
    end

    it "includes collection error if set" do
      SiteSettings.model_path_prefix_template = "{collection}/{modelName}{modelId}"
      expect(model.formatted_path).to eq "unset-collection/batarang#1"
    end

    it "includes non-token information as literal text" do
      SiteSettings.model_path_prefix_template = "{tags}/{creator} - {collection} - {modelName}{modelId}"
      expect(model.formatted_path).to eq "@untagged/unset-creator - unset-collection - batarang#1"
    end
  end

  context "when creating model directory name" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes model ID if option is included" do
      SiteSettings.model_path_prefix_template = "{modelName}{modelId}"
      expect(model.formatted_path).to eq "batarang#1"
    end

    it "does not include model ID if option is deselected" do
      SiteSettings.model_path_prefix_template = "{modelName}"
      expect(model.formatted_path).to eq "batarang"
    end
  end
end
