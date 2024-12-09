require "rails_helper"

RSpec.describe "Webfinger", :multiuser do
  context "when looking up a creator by at_address" do
    let(:creator) { create(:creator) }

    before do
      get("/.well-known/webfinger?resource=acct:#{creator.federails_actor.at_address}")
    end

    it "returns a successful response" do
      expect(response).to have_http_status :success
    end

    it "responds with data on the correct user" do
      expect(response.parsed_body["links"][0]["href"]).to eq creator.federails_actor.federated_url
    end
  end

  [
    :user,
    :collection,
    :creator,
    :model
  ].each do |followable|
    context "when looking up a #{followable} by URL" do
      let(:object) { create(followable) }

      before do
        get("/.well-known/webfinger?resource=#{object.federails_actor.federated_url}")
      end

      it "returns a successful response" do
        expect(response).to have_http_status :success
      end

      it "responds with data on the correct #{followable}" do
        expect(response.parsed_body["links"][0]["href"]).to eq object.federails_actor.federated_url
      end

      it "returns a not found response if item doesn't exist" do
        expect { get("/.well-known/webfinger?resource=#{object.federails_actor.federated_url}9999") }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
