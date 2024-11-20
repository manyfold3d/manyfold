require "rails_helper"

RSpec.describe "/settings/users" do
  describe "GET /index", :as_moderator do
    it "renders a successful response" do
      create(:user)
      get users_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      user = Settings::User.create! valid_attributes
      get user_url(user)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
end
