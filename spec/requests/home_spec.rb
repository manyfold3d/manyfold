require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end
end
