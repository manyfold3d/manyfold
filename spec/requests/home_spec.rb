require "rails_helper"

# root GET    /                                                                       home#index

RSpec.describe "Home" do
  context "when signed out" do
    it "needs testing"
  end

  context "when signed in" do
    before do
      sign_in create(:user)
    end

    describe "GET /" do
      it "redirects to library creation if there isn't one already" do
        get "/"
        expect(response).to redirect_to("/libraries/new")
      end

      it "shows the homepage if a library has been created" do
        create(:library)
        get "/"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
