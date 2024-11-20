require "rails_helper"

RSpec.describe "/settings/users", type: :request do

  describe "GET /index", :as_moderator do
    it "renders a successful response" do
      create(:user)
      get users_url
      expect(response).to be_successful
    end
  end
