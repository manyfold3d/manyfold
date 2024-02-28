require "rails_helper"

RSpec.describe "Creators" do
  before do
    build_list(:creator, 13) do |creator|
      creator.save! # See https://dev.to/hernamvel/the-optimal-way-to-create-a-set-of-records-with-factorybot-createlist-factorybot-buildlist-1j64
      create_list(:link, 1, linkable: creator)
      create_list(:model, 1, creator: creator)
    end
  end

  describe "GET /creators?page=2" do
    it "returns paginated creators" do
      get "/creators?page=2"
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/pagination/)
    end
  end
end
