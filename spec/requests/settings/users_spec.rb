require "rails_helper"

RSpec.describe "/settings/users", :multiuser do
  describe "GET /index", :as_moderator do
    before { create(:user) }

    it "renders a successful response" do
      get "/settings/users"
      expect(response).to be_successful
    end
  end

  describe "GET /show", :as_moderator do
    let(:user) { create(:user) }

    it "renders a successful response" do
      get "/settings/users/#{user.to_param}"
      expect(response).to be_successful
    end
  end
end
