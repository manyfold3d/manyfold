require "rails_helper"

RSpec.describe "Webfinger", :multiuser do
  context "when looking up a user by federation URL" do
    let(:user) { create(:user) }

    before do
      get("/.well-known/webfinger?resource=#{user.actor.federated_url}")
    end

    it "returns a successful response" do
      expect(response).to have_http_status :success
    end

    it "responds with data on the correct user" do
      expect(response.parsed_body["links"][0]["href"]).to eq user.actor.federated_url
    end
  end

  context "when looking up a user by at_address" do
    let(:user) { create(:user) }

    before do
      get("/.well-known/webfinger?resource=acct:#{user.actor.at_address}")
    end

    it "returns a successful response" do
      expect(response).to have_http_status :success
    end

    it "responds with data on the correct user" do
      expect(response.parsed_body["links"][0]["href"]).to eq user.actor.federated_url
    end
  end

  context "when looking up a non-existent user" do
    let(:user) { create(:user) }

    before do
      get("/.well-known/webfinger?resource=#{user.actor.federated_url}9999")
    end

    it "returns a not found response"
  end

  [
    :collection,
    :creator,
    :model
  ].each do |followable|
    context "when looking up a #{followable}" do
      let(:object) { create(followable) }

      before do
        get("/.well-known/webfinger?resource=#{object.actor.federated_url}")
      end

      it "returns a successful response" do
        expect(response).to have_http_status :success
      end

      it "responds with data on the correct #{followable}" do
        expect(response.parsed_body["links"][0]["href"]).to eq object.actor.federated_url
      end
    end
  end
end
