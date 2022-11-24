require "rails_helper"

RSpec.describe "Collections", type: :request do
  describe "GET /show" do
    it "returns http success" do
      pending
      get "/collections/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /index" do
    it "returns http success" do
      pending
      get "/collections/index"
      expect(response).to have_http_status(:success)
    end
  end
end
