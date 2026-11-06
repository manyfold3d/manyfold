require "rails_helper"

RSpec.describe Form::ModelDeserializer do
  subject(:deserializer) { described_class.new(params: params, user: user, record: record) }

  let(:params) {
    ActionController::Parameters.new(
      "_method" => "patch",
      "authenticity_token" => "[FILTERED]",
      "model" => ActionController::Parameters.new({
        "name" => "Batarang",
        "preview_file" => "abc123",
        "entrypoint" => "abc123",
        "entrypoint_fragment" => "fragment",
        "creator" => "abc123",
        "library" => "abc123",
        "tag_list" => ["wonderful", "toys"],
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

  context "when only providing a single field" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model) }
    let(:params) {
      ActionController::Parameters.new(
        "model" => ActionController::Parameters.new({
          "name" => "Batarang"
        })
      )
    }

    it "only permits that field" do
      expect(deserializer.deserialize.keys).to eq ["name"]
    end
  end

  context "when setting a creator" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model, owner: user) }
    let(:params) {
      ActionController::Parameters.new(
        "model" => ActionController::Parameters.new({
          "creator" => creator.to_param
        })
      )
    }

    context "when the user doesn't have update permission on the creator" do
      let(:creator) { create(:creator) }

      it "does not set creator" do
        expect(deserializer.deserialize[:creator]).to be_nil
      end
    end

    context "when the user does have update permission on the creator" do
      let(:creator) { create(:creator, owner: user) }

      it "finds proper creator record" do
        expect(deserializer.deserialize[:creator]).to eq creator
      end
    end
  end

  context "when setting collections" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model, owner: user) }
    let(:params) {
      ActionController::Parameters.new(
        "model" => ActionController::Parameters.new({
          "collection_ids" => [collection.to_param]
        })
      )
    }

    context "when the user doesn't have update permission on the collection" do
      let(:collection) { create(:collection) }

      it "does not set collections" do
        expect(deserializer.deserialize[:collections]).to be_empty
      end

      it "strips collection_ids param" do
        expect(deserializer.deserialize[:collection_ids]).to be_nil
      end
    end

    context "when the user does have update permission on the collection" do
      let(:collection) { create(:collection, owner: user) }

      it "finds proper collection record" do
        expect(deserializer.deserialize[:collections]).to eq [collection]
      end

      it "strips collection_ids param" do
        expect(deserializer.deserialize[:collection_ids]).to be_nil
      end
    end
  end

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
