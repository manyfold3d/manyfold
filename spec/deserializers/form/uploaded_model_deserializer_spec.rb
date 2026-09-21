require "rails_helper"

RSpec.describe Form::UploadedModelDeserializer do
  subject(:deserializer) { described_class.new(params: params, user: user, record: record) }

  context "when setting a creator" do
    let(:user) { create(:contributor) }
    let(:record) { create(:model, owner: user) }
    let(:params) {
      ActionController::Parameters.new(
        "model" => ActionController::Parameters.new({
          "creator_id" => creator.id
        })
      )
    }

    context "when the user doesn't have update permission on the creator" do
      let(:creator) { create(:creator) }

      it "does not set creator" do
        expect(deserializer.deserialize[:creator]).to be_nil
      end

      it "strips creator_id param" do
        expect(deserializer.deserialize[:creator_id]).to be_nil
      end
    end

    context "when the user does have update permission on the creator" do
      let(:creator) { create(:creator, owner: user) }

      it "finds proper creator record" do
        expect(deserializer.deserialize[:creator]).to eq creator
      end

      it "strips creator_id param" do
        expect(deserializer.deserialize[:creator_id]).to be_nil
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
end
