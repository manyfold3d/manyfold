require "rails_helper"

#  user_settings GET    /users/:user_id/settings(.:format)                                      settings#show
#                PATCH  /users/:user_id/settings(.:format)                                      settings#update
#                PUT    /users/:user_id/settings(.:format)                                      settings#update

RSpec.describe "Settings" do
  let(:user) { create(:user) }

  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    before do
      sign_in user
    end

    describe "GET /users/:user_id/settings" do
      it "returns http success" do
        get "/users/#{user.username}/settings"
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /users/:user_id/settings" do
      it "redirects back to settings on success" do
        patch "/users/#{user.username}/settings"
        expect(response).to redirect_to("/users/#{user.username}/settings")
      end
    end

    describe "PUT /users/:user_id/settings" do
      it "redirects back to settings on success" do
        put "/users/#{user.username}/settings"
        expect(response).to redirect_to("/users/#{user.username}/settings")
      end
    end
  end
end
