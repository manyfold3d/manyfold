require "rails_helper"

RSpec.describe "Problems" do
  describe "GET /index" do
    it "returns http success" do
      get "/problems/index"
      expect(response).to have_http_status(:success)
    end
  end
end
