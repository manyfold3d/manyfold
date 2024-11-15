require "rails_helper"

#  user_settings GET    /users/:user_id/settings(.:format)                                      settings#show
#                PATCH  /users/:user_id/settings(.:format)                                      settings#update
#                PUT    /users/:user_id/settings(.:format)                                      settings#update

RSpec.describe "Settings" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in", :as_administrator do
    describe "GET /settings" do
      it "returns http success" do
        get "/settings"
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /settings" do
      it "redirects back to settings on success" do
        patch "/settings"
        expect(response).to redirect_to("/settings")
      end
    end

    describe "PUT /settings" do
      it "redirects back to settings on success" do
        put "/settings"
        expect(response).to redirect_to("/settings")
      end
    end
  end
end
