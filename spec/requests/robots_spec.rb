require "rails_helper"

RSpec.describe "Robots" do
  describe "GET /robots.txt" do
    it "returns http success if crawling is not enabled (default)" do
      allow(SiteSettings).to receive(:allow_robots).and_return(false)
      get "/robots.txt"
      expect(response).to have_http_status(:success)
    end

    it "excludes all robots if crawling is not enabled (default)" do # rubocop:disable RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:allow_robots).and_return(false)
      get "/robots.txt"
      expect(response.body).to include "User-Agent: *"
      expect(response.body).to include "Disallow: /"
      expect(response.body).not_to include "Allow: /"
    end

    it "allows robots if crawling is enabled" do
      allow(SiteSettings).to receive(:allow_robots).and_return(true)
      get "/robots.txt"
      expect(response.body).to include "Allow: /"
    end

    it "includes sitemap link if crawling is enabled" do
      allow(SiteSettings).to receive(:allow_robots).and_return(true)
      get "/robots.txt"
      expect(response.body).to include "Sitemap: http://www.example.com/sitemap.xml"
    end

    it "does not include AI training directives if AI training is enabled" do # rubocop:disable RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:allow_ai_bots).and_return(true)
      get "/robots.txt"
      expect(response.body).not_to include "DisallowAITraining: /"
      expect(response.body).not_to include "Content-Usage: ai=n"
      expect(response.body).not_to include "GPTBot"
    end

    it "includes AI training directives if AI training is disabled" do # rubocop:disable RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:allow_ai_bots).and_return(false)
      get "/robots.txt"
      expect(response.body).to include "DisallowAITraining: /"
      expect(response.body).to include "Content-Usage: ai=n"
    end

    it "excludes known AI bots if AI training is disabled" do # rubocop:disable RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:allow_ai_bots).and_return(false)
      get "/robots.txt"
      expect(response.body).to include "User-Agent: FirecrawlAgent\nDisallow: /"
    end
  end

  describe "GET /sitemap.xml" do
    it "returns http success" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:success)
    end
  end
end
