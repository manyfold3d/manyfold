require "rails_helper"

RSpec.describe "Robots" do
  describe "GET /robots.txt" do
    it "returns http success" do
      get "/robots.txt"
      expect(response).to have_http_status(:success)
    end

    it "excludes all robots" do
      get "/robots.txt"
      expect(response.body).to include "User-agent: *\nDisallow: /"
    end
  end
end
