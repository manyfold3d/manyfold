require "rails_helper"

RSpec.describe Form::CollectionDeserializer do
  subject(:deserializer) { described_class.new(params: params, user: user, record: record) }

  context "when setting a creator by public ID" do
    let(:user) { create(:contributor) }
    let(:record) { create(:collection, owner: user) }
    let(:params) {
      ActionController::Parameters.new(
        "collection" => ActionController::Parameters.new({
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

  context "when setting parent collection by public ID" do
    let(:user) { create(:contributor) }
    let(:record) { create(:collection, owner: user) }
    let(:params) {
      ActionController::Parameters.new(
        "collection" => ActionController::Parameters.new({
          "collection" => parent.to_param
        })
      )
    }

    context "when the user doesn't have update permission on the parent collection" do
      let(:parent) { create(:collection) }

      it "does not set collection" do
        expect(deserializer.deserialize[:collection]).to be_nil
      end
    end

    context "when the user has update permission on the parent collection" do
      let(:parent) { create(:collection, owner: user) }

      it "finds proper collection record" do
        expect(deserializer.deserialize[:collection]).to eq parent
      end
    end
  end
end
