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
      SiteSettings.model_path_prefix_template = "{creator}"
      expect(model.formatted_path).to eq "/Bruce Wayne/batarang#1"
    end

    it "includes tags if set" do
      SiteSettings.model_path_prefix_template = "{tags}"
      expect(model.formatted_path).to eq "/bat/weapon/batarang#1"
    end

    it "includes collection if set" do
      SiteSettings.model_path_prefix_template = "{collection}"
      expect(model.formatted_path).to eq "/gadgets/batarang#1"
    end

    it "includes multiple metadata types if set" do
      SiteSettings.model_path_prefix_template = "{collection}/{creator}/{tags}"
      expect(model.formatted_path).to eq "/gadgets/Bruce Wayne/bat/weapon/batarang#1"
    end

    it "includes error path for unknown prefixes" do
      SiteSettings.model_path_prefix_template = "{bad}"
      expect(model.formatted_path).to eq "/bad-formatted-path-element/batarang#1"
    end
  end

  context "when creating path from missing model metadata" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes creator error if set" do
      SiteSettings.model_path_prefix_template = "{creator}"
      expect(model.formatted_path).to eq "/unset-creator/batarang#1"
    end

    it "handles zero tags" do
      SiteSettings.model_path_prefix_template = "{tags}"
      expect(model.formatted_path).to eq "/batarang#1"
    end

    it "includes collection error if set" do
      SiteSettings.model_path_prefix_template = "{collection}"
      expect(model.formatted_path).to eq "/unset-collection/batarang#1"
    end
  end

  context "when creating model directory name" do
    let(:model) { create(:model, name: "Batarang") }

    it "includes model ID if option is selected" do
      SiteSettings.model_path_prefix_template = ""
      SiteSettings.model_path_suffix_model_id = true
      expect(model.formatted_path).to eq "/batarang#1"
    end

    it "does not include model ID if option is deselected" do
      SiteSettings.model_path_prefix_template = ""
      SiteSettings.model_path_suffix_model_id = false
      expect(model.formatted_path).to eq "/batarang"
    end
  end
end
