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

    it "allows robots if crawling is enabled" do
      allow(SiteSettings).to receive(:allow_robots).and_return(true)
      get "/robots.txt"
      expect(response.body).to include "User-agent: *\nAllow: /"
    end

    it "includes sitemap link if crawling is enabled" do
      allow(SiteSettings).to receive(:allow_robots).and_return(true)
      get "/robots.txt"
      expect(response.body).to include "Sitemap: http://www.example.com/sitemap.xml"
    end
  end

  describe "GET /sitemap.xml" do
    it "returns http success" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:success)
    end
  end
end
