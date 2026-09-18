require "rails_helper"

RSpec.describe "OAuth access token request", :after_first_run, :multiuser do
  context "when interactively creating tokens as moderator", :as_moderator do
    describe "GET /oauth/applications/{id}/tokens/new" do
      it "can issue new tokens for most users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        get "/oauth/applications/#{app.to_param}/tokens/new"
        expect(response).to have_http_status :success
      end

      it "cannot issue new tokens for admin-owned apps" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        get "/oauth/applications/#{app.to_param}/tokens/new"
        expect(response).to have_http_status :forbidden
      end
    end

    describe "POST /oauth/applications/{id}/tokens" do
      let(:params) { {doorkeeper_access_token: {expiry: "7", scopes: ["read"]}} }

      it "can issue new tokens for most users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        post "/oauth/applications/#{app.to_param}/tokens", params: params
        expect(response).to redirect_to("http://www.example.com/oauth/applications/1/tokens/1")
      end

      it "cannot issue new tokens for admin-owned apps" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        post "/oauth/applications/#{app.to_param}/tokens", params: params
        expect(response).to have_http_status :forbidden
      end
    end

    describe "DELETE /oauth/applications/{application_id}/tokens/{id}" do
      it "can revoke tokens for most users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        token = app.access_tokens.create
        delete "/oauth/applications/#{app.to_param}/tokens/#{token.to_param}"
        expect(response).to redirect_to("http://www.example.com/oauth/applications/1")
      end

      it "cannot revoke tokens for admin-owned apps" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        token = app.access_tokens.create
        delete "/oauth/applications/#{app.to_param}/tokens/#{token.to_param}"
        expect(response).to have_http_status :forbidden
      end
    end
  end

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

  context "when using read tokens to perform actions" do
    let(:owner) { create(:contributor) }
    let(:application) { Doorkeeper::Application.create! owner: owner, name: "test app" }
    let(:read_token) { create(:oauth_access_token, application: application, scopes: "read") }
    let(:model) { create(:model, owner: owner) }
    let(:file) { create(:model_file, model: model, filename: "test.zip") }

    it "fails safe for non-standard actions" do
      post extract_model_model_file_path(model, file), headers: {
        "Authorization" => "Bearer #{read_token.plaintext_token}",
        "Accept" => Mime[:manyfold_api_v0].to_s
      }
      expect(response).to have_http_status :forbidden
    end
  end

  context "when using public tokens" do
    let(:owner) { create(:contributor) }
    let(:application) { Doorkeeper::Application.create! owner: create(:user), name: "test app" }
    let(:token) { create(:oauth_access_token, application: application, scopes: ["public", "upload"]) }

    it "fails on non-public models" do
      get model_path(create(:model, owner: owner)), headers: {
        "Authorization" => "Bearer #{token.plaintext_token}",
        "Accept" => Mime[:manyfold_api_v0].to_s
      }
      expect(response).to have_http_status :not_found
    end

    it "succeeds on public models" do
      get model_path(create(:model, :public)), headers: {
        "Authorization" => "Bearer #{token.plaintext_token}",
        "Accept" => Mime[:manyfold_api_v0].to_s
      }
      expect(response).to have_http_status :success
    end
  end
end
