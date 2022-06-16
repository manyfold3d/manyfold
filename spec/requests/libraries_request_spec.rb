require "rails_helper"

RSpec.describe "Libraries", type: :request do
  before :all do
    @library = FactoryBot.create(:library) do |library|
      FactoryBot.create_list(:model, 13, library: library)
    end
  end

  describe "GET /libraries" do
    it "redirects to the first available library" do
      get "/libraries"
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /libraries/1" do
    it "returns http success" do
      get "/libraries/1"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /libraries/{id}?page=2" do
    it "returns paginated models" do
      get "/libraries/#{@library.id}?page=2"
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/pagination/)
    end
  end
end
