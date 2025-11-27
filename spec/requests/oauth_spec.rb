require "rails_helper"

RSpec.describe "OAuth access token request", :after_first_run do
  context "when using client_credentials grant" do
    let(:oauth_app) { Doorkeeper::Application.create! owner: User.first, name: "test app" }
    let(:client_credentials_params) do
      {
        grant_type: "client_credentials",
        client_id: oauth_app.uid,
        client_secret: oauth_app.secret
      }
    end

    it "succeeds" do
      post "/oauth/token", params: client_credentials_params
      expect(response).to have_http_status :success
    end

    it "is forbidden with bad credentials" do
      post "/oauth/token", params: client_credentials_params.merge(client_secret: "wrong")
      expect(response).to have_http_status :unauthorized
    end

    it "issues an access token" do
      post "/oauth/token", params: client_credentials_params
      expect(response.parsed_body["access_token"]).to be_present
    end

    it "rate limits token requests" do
      Rails.cache.increment("rate-limit:doorkeeper_tokens:127.0.0.1", 10, expires_in: 1.minute)
      post "/oauth/token", params: client_credentials_params
      expect(response).to have_http_status :too_many_requests
    end
  end
end
