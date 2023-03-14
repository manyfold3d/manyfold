require "rails_helper"

RSpec.describe "Collections" do
  before :all do
    create_list(:collection, 13) do |collection|
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
