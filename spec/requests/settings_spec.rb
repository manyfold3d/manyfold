require "rails_helper"

#  user_settings GET    /users/:user_id/settings(.:format)                                      settings#show
#                PATCH  /users/:user_id/settings(.:format)                                      settings#update
#                PUT    /users/:user_id/settings(.:format)                                      settings#update

RSpec.describe "Settings" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    describe "GET /users/:user_id/settings", :as_viewer do
      it "returns http success" do
        get "/users/#{User.first.username}/settings"
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /users/:user_id/settings", :as_viewer do
      it "redirects back to settings on success" do
        patch "/users/#{User.first.username}/settings"
        expect(response).to redirect_to("/users/#{User.first.username}/settings")
      end
    end

    describe "PUT /users/:user_id/settings", :as_viewer do
      it "redirects back to settings on success" do
        put "/users/#{User.first.username}/settings"
        expect(response).to redirect_to("/users/#{User.first.username}/settings")
      end
    end
  end
end
