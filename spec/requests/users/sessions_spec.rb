require "rails_helper"

#     new_user_session GET    /users/sign_in(.:format)                                                devise/sessions#new
#         user_session POST   /users/sign_in(.:format)                                                devise/sessions#create
# destroy_user_session DELETE /users/sign_out(.:format)                                               devise/sessions#destroy

RSpec.describe "Users::Sessions" do
  let!(:admin) { create(:user, admin: true) }

  context "when in multiuser mode", :multiuser do
    context "when signed out" do
      describe "GET /users/sign_in" do
        it "shows login page" do
          get "/users/sign_in"
          expect(response).to have_http_status(:success)
        end
      end
    end

    context "when signed in" do
      describe "GET /users/sign_in" do
        before { sign_in admin }

        it "redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end
  end

  context "when in single user mode" do
    context "when signed out" do
      describe "GET /users/sign_in" do
        it "auto logs in and redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end

    context "when signed in" do
      describe "GET /users/sign_in" do
        before { sign_in admin }

        it "redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end
  end
end
