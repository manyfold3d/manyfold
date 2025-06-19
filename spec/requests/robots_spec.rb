require "rails_helper"

RSpec.describe "Robots" do
  describe "GET /robots.txt" do
    it "returns http success if crawling is not enabled (default)" do
      allow(SiteSettings).to receive(:allow_robots).and_return(false)
      get "/robots.txt"
      expect(response).to have_http_status(:success)
    end

    it "excludes all robots if crawling is not enabled (default)" do
      allow(SiteSettings).to receive(:allow_robots).and_return(false)
      get "/robots.txt"
      expect(response.body).to include "User-agent: *\nDisallow: /"
    end

    it "doesn't serve robots.txt if crawling is enabled" do
      allow(SiteSettings).to receive(:allow_robots).and_return(true)
      get "/robots.txt"
      expect(response).to have_http_status(:not_found)
    end
  end
  end
end
