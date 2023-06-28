require "rails_helper"

RSpec.describe "Collections" do
  before :all do
    build_list(:collection, 13) do |collection|
      collection.save! # See https://dev.to/hernamvel/the-optimal-way-to-create-a-set-of-records-with-factorybot-createlist-factorybot-buildlist-1j64
      create_list(:link, 1, linkable: collection)
      create_list(:model, 1, collection: collection)
    end
  end

  describe "GET /collections?page=2" do
    it "returns paginated collections" do
      get "/collections?page=2"
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/pagination/)
    end
  end
end
