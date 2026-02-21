require "rails_helper"

RSpec.describe Form::ModelDeserializer do
  subject(:deserializer) { described_class.new(params: params, user: user, record: record) }

  let(:params) {
    ActionController::Parameters.new(
      "_method" => "patch",
      "authenticity_token" => "[FILTERED]",
      "model" => ActionController::Parameters.new({
        "name" => "Batarang",
        "preview_file_id" => "12345",
        "creator_id" => "93",
        "library_id" => "20",
        "tag_list" => ["wonderful", "toys"],
        "collection_id" => "34",
        "links_attributes" => ActionController::Parameters.new({
          "0" => {"url" => "https://example.com", "_destroy" => "false"}
        }),
        "caption" => "",
        "notes" => "",
        "license" => "LicenseRef-Commercial",
        "sensitive" => "0",
        "indexable" => "inherit",
        "permission_preset" => "",
        "caber_relations_attributes" => ActionController::Parameters.new({
          "0" => {"id" => "1"},
          "1" => {"permission" => "edit", "_destroy" => "false", "id" => "2"},
          "2" => {"permission" => "preview", "_destroy" => "true", "id" => "3"}
        })
      }),
      "commit" => "Save",
      "id" => "42"
    )
  }

  context "when the user is the owner of the model" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model, owner: user) }

    it "permits all caber relations" do
      expect(deserializer.deserialize[:caber_relations_attributes].keys.length).to eq 3
    end

    it "flags caber relations for destruction" do
      expect(deserializer.deserialize[:caber_relations_attributes]["2"]["_destroy"]).to eq "true"
    end
  end

  context "when the user is not the owner of the model" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model, owner: create(:user)) }

    it "filters out caber relations" do
      expect(deserializer.deserialize).not_to have_key(:caber_relations_attributes)
    end

    it "filters out permission preset" do
      expect(deserializer.deserialize).not_to have_key(:permission_preset)
    end
  end
end
