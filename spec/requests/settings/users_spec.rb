require "rails_helper"

RSpec.describe "/settings/users", :multiuser do
  describe "GET /index", :as_moderator do
    it "renders a successful response" do
      create(:user)
      get "/settings/users"
      expect(response).to be_successful
    end
  end

  describe "GET /show", :as_moderator do
    it "renders a successful response" do
      user = create(:user)
      get "/settings/users/#{user.to_param}"
      expect(response).to be_successful
    end
  end
end
