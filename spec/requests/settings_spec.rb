require "rails_helper"

RSpec.describe "Settings" do
  before do
    sign_in create(:user)
  end

  let(:username) { User.first.username }

  describe "GET /" do
    it "returns http success" do
      get "/users/#{username}/settings"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /" do
    it "returns http success" do
      patch "/users/#{username}/settings"
      expect(response).to have_http_status(:redirect)
    end
  end
end
