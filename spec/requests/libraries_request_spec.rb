require "rails_helper"

RSpec.describe "Libraries" do
  before do
    sign_in create(:user)
    @library = create(:library) do |library|
      create_list(:model, 2, library: library)
    end
  end

  describe "GET /libraries" do
    it "redirects to models index" do
      get "/libraries"
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /libraries/1" do
    it "redirects to models index with library filter" do
      get "/libraries/1"
      expect(response).to have_http_status(:redirect)
    end
  end
end
