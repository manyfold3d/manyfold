require "rails_helper"

RSpec.describe "Models", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/models/show"
      expect(response).to have_http_status(:success)
    end
  end
end
