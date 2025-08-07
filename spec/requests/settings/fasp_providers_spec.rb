require "rails_helper"

RSpec.describe "/fasp/providers", :multiuser do
  describe "GET /fasp/providers" do
    it "denies access to anything except admin", :as_moderator do
      get "/fasp/providers"
      expect(response).to have_http_status :forbidden
    end

    it "allows admins", :as_administrator do
      get "/fasp/providers"
      expect(response).to have_http_status :success
    end
  end

  describe "GET /fasp/providers/{id}/edit" do
    let(:provider) { create(:provider) }

    it "denies access to anything except admin", :as_moderator do
      get "/fasp/providers/#{provider.id}/edit"
      expect(response).to have_http_status :forbidden
    end

    it "allows admins", :as_administrator do
      get "/fasp/providers/#{provider.id}/edit"
      expect(response).to have_http_status :success
    end
  end

  describe "PATCH /fasp/providers/{id}" do
    let(:provider) { create(:provider) }

    it "denies access to anything except admin", :as_moderator do
      patch "/fasp/providers/#{provider.id}"
      expect(response).to have_http_status :forbidden
    end

    it "allows admins", :as_administrator do
      patch "/fasp/providers/#{provider.id}"
      # Bad request because no params, but not forbidden!
      expect(response).to have_http_status :bad_request
    end
  end

  describe "POST /fasp/registration" do
    it "is allowed without authentication" do
      post "/fasp/registration"
      # Bad request because no params, but not forbidden!
      expect(response).to have_http_status :bad_request
    end
  end
end
