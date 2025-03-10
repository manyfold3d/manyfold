require "rails_helper"

RSpec.describe "Admin::Models" do
  it "is inaccessible to anything less than admin", :as_moderator do
    get "/admin/models"
    expect(response).to have_http_status(:unauthorized)
  end

  context "with admin permission", :as_administrator do
    it "is accessible" do
      get "/admin/models"
      expect(response).to have_http_status(:success)
    end

    it "is inaccessible in demo mode", :demo_mode do
      get("/admin/models")
      expect(response).to have_http_status(:forbidden)
    end
  end
end
