require "rails_helper"

#     new_user_session GET    /users/sign_in(.:format)                                                devise/sessions#new
#         user_session POST   /users/sign_in(.:format)                                                devise/sessions#create
# destroy_user_session DELETE /users/sign_out(.:format)                                               devise/sessions#destroy

RSpec.describe "Users::Sessions" do
  context "when in multiuser mode", :multiuser do
    context "when signed out on first use" do
      describe "GET /users/sign_in" do
        it "creates a default account" do
          expect { get "/users/sign_in" }.to change(User, :count).from(0).to(1)
        end

        it "gives default account admin permissions" do
          get "/users/sign_in"
          expect(User.first.is_administrator?).to be true
        end

        it "automatically logs in on first use" do
          get "/users/sign_in"
          expect(controller.current_user).to be_present
        end
      end
    end

    context "when signed out after first use" do
      describe "GET /users/sign_in" do
        let(:admin) { create(:admin) }

        before do
          admin.update(reset_password_token: nil)
        end

        it "doesn't auto sign in" do
          get "/users/sign_in"
          expect(controller.current_user).to be_nil
        end

        it "shows login page" do
          get "/users/sign_in"
          expect(response).to have_http_status(:success)
        end
      end

      describe "POST /users/sign_in" do
        let(:password) { SecureRandom.hex }
        let(:admin) { create(:admin, password: password, password_confirmation: password) }

        it "succeeds and redirects to homepage with good credentials" do
          post "/users/sign_in", params: {user: {email: admin.email, password: password}}
          expect(response).to redirect_to("/")
        end

        it "fails with bad credentials" do
          post "/users/sign_in", params: {user: {email: admin.email, password: "nope"}}
          expect(response).to have_http_status :unprocessable_content
        end

        it "rate limits login attempts" do
          Rails.cache.increment("rate-limit:users/sessions:127.0.0.1", 10, expires_in: 1.minute)
          post "/users/sign_in", params: {user: {email: admin.email, password: password}}
          expect(response).to have_http_status :too_many_requests
        end
      end
    end

    context "when signed in", :as_member do
      describe "GET /users/sign_in" do
        it "redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end
  end

  context "when in single user mode", :singleuser do
    context "when signed out" do
      describe "/" do
        it "forces login" do
          expect(get("/")).to redirect_to("/users/sign_in")
        end
      end

      describe "GET /users/sign_in" do
        it "creates a default account" do
          expect { get "/users/sign_in" }.to change(User, :count).from(0).to(1)
        end

        it "gives default account admin permissions" do
          get "/users/sign_in"
          expect(controller.current_user.is_administrator?).to be true
        end

        it "auto logs in and redirects to root" do
          get "/users/sign_in"
          expect(controller.current_user).to be_present
        end

        it "redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end

    context "when signed in", :as_member do
      describe "GET /users/sign_in" do
        it "redirects to root" do
          get "/users/sign_in"
          expect(response).to redirect_to("/")
        end
      end
    end
  end
end
