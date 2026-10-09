require "rails_helper"

# Per-resource rejection checks live in the "CSRF protected" shared example
# (spec/requests/csrf_protected_shared.rb). This file covers the app-wide
# behaviour: valid tokens are accepted, and API requests using bearer tokens
# don't need one.
RSpec.describe "CSRF protection", :after_first_run do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  context "with a signed-in browser session", :as_contributor do
    it "accepts a state-changing request with the authenticity token from the form" do
      get "/collections/new"
      token = response.parsed_body.at_css("form input[name='authenticity_token']")["value"]
      post "/collections", params: {collection: {name: "legitimate"}, authenticity_token: token}
      expect(response).to redirect_to("/collections")
    end
  end

  context "with an API request authenticated by access token" do
    let(:owner) { create(:contributor) }
    let(:application) { Doorkeeper::Application.create! owner: owner, name: "test app" }
    let(:access_token) { create(:oauth_access_token, application: application, scopes: "write") }

    let(:headers) {
      {
        "Authorization" => "Bearer #{access_token.plaintext_token}",
        "Content-Type" => Mime[:manyfold_api_v0].to_s,
        "Accept" => Mime[:manyfold_api_v0].to_s
      }
    }

    let(:body) { {name: "via api"}.to_json }

    it "accepts a state-changing request without an authenticity token" do
      post "/collections", params: body, headers: headers
      expect(response).to have_http_status(:created)
    end

    it "creates the record without an authenticity token" do
      expect {
        post "/collections", params: body, headers: headers
      }.to change(Collection, :count).by(1)
    end
  end
end
