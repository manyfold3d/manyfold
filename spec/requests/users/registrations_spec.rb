require "rails_helper"

# cancel_user_registration GET    /users/cancel(.:format)                                                 users/registrations#cancel
#    new_user_registration GET    /users/sign_up(.:format)                                                users/registrations#new
#   edit_user_registration GET    /users/edit(.:format)                                                   users/registrations#edit
#        user_registration PATCH  /users(.:format)                                                        users/registrations#update
#                          PUT    /users(.:format)                                                        users/registrations#update
#                          DELETE /users(.:format)                                                        users/registrations#destroy
#                          POST   /users(.:format)                                                        users/registrations#create

RSpec.describe "Users::Registrations" do
  let(:old_password) { Faker::Internet.password min_length: 6, mix_case: true, special_characters: true }
  let(:new_password) { Faker::Internet.password min_length: 6, mix_case: true, special_characters: true }
  let!(:admin) {
    create(:admin, password: old_password)
  }
  let(:post_options) {
    {
      user: {
        email: Faker::Internet.email,
        username: Faker::Internet.username(specifier: 3, separators: []),
        password: old_password,
        password_confirmation: old_password
      }
    }
  }
  let(:patch_options) {
    {
      user: {
        email: Faker::Internet.email,
        password: new_password,
        password_confirmation: new_password,
        current_password: old_password
      }
    }
  }

  context "when in single user mode" do
    context "when signed out" do
      describe "GET /users/sign_up" do
        it "raises an error" do
          expect { get "/users/sign_up" }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "POST /users" do
        it "raises an error" do
          expect { post "/users", params: post_options }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "GET /users/edit" do
        it "redirects to sign in page" do
          get "/users/edit"
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "PATCH /users/" do
        it "redirects to sign in page" do
          patch "/users", params: patch_options
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "DELETE /users" do
        it "redirects to sign in page" do
          delete "/users"
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "GET /users/cancel without a signup in progress" do
        it "raises an error" do
          expect { get "/users/cancel" }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end

    context "when signed in" do
      before { sign_in admin }

      describe "GET /users/sign_up" do
        before { get "/users/sign_up" }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end
      end

      describe "POST /users" do
        before { post "/users", params: post_options }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "does not create a user" do
          expect(User.count).to eq 1
        end
      end

      describe "GET /users/edit" do
        before { get "/users/edit" }

        it "shows edit page" do
          expect(response).to have_http_status(:success)
        end
      end

      describe "PATCH /users/" do
        before { patch "/users", params: patch_options }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "updates password" do
          expect(User.first.valid_password?(new_password)).to be true
        end
      end

      describe "DELETE /users" do
        it "raises an error" do
          expect { delete "/users" }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "GET /users/cancel without a signup in progress" do
        before { get "/users/cancel" }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end
      end
    end
  end

  context "when in multiuser mode with closed registrations", :multiuser do
    before do
      allow(SiteSettings).to receive(:registration_enabled).and_return(false)
    end

    context "when signed out" do
      describe "GET /users/sign_up" do
        it "raises an error" do
          expect { get "/users/sign_up" }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "POST /users" do
        it "raises an error" do
          expect { post "/users", params: post_options }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "GET /users/edit" do
        before { get "/users/edit" }

        it "redirects to sign in page" do
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "PATCH /users/" do
        before { patch "/users", params: patch_options }

        it "redirects to sign in page" do
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "DELETE /users" do
        before { delete "/users" }

        it "redirects to sign in page" do
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "GET /users/cancel without a signup in progress" do
        before { get "/users/cancel" }

        it "redirects to sign up page" do
          expect(response).to redirect_to("/users/sign_up")
        end
      end
    end

    context "when signed in" do
      before { sign_in admin }

      describe "GET /users/sign_up" do
        before { get "/users/sign_up" }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end
      end

      describe "POST /users" do
        before { post "/users", params: post_options }

        it "does not create a new user" do
          expect(User.count).to eq 1
        end

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end
      end

      describe "GET /users/edit" do
        before { get "/users/edit" }

        it "shows edit page" do
          expect(response).to have_http_status(:success)
        end
      end

      describe "PATCH /users/" do
        before { patch "/users", params: patch_options }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "updates password" do
          expect(User.first.valid_password?(new_password)).to be true
        end
      end

      describe "DELETE /users" do
        before { delete "/users" }

        it "removes the user" do
          expect(User.count).to eq 0
        end

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "signs out the user" do
          expect(controller.current_user).to be_nil
        end
      end

      describe "GET /users/cancel without a signup in progress" do
        before { get "/users/cancel" }

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end
      end
    end
  end

  context "when in multiuser mode with open registrations", :multiuser do
    before do
      allow(SiteSettings).to receive(:registration_enabled).and_return(true)
    end

    context "when signed out" do
      describe "GET /users/sign_up" do
        before { get "/users/sign_up" }

        it "shows signup page" do
          expect(response).to have_http_status(:success)
        end
      end

      describe "POST /users" do
        before { post "/users", params: post_options }

        it "creates a new user" do
          expect(User.count).to eq 2
        end

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "signs in the user" do
          expect(controller.current_user&.username).to eq post_options[:user][:username]
        end
      end

      describe "GET /users/cancel without a signup in progress" do
        before { get "/users/cancel" }

        it "redirects to sign up page" do
          expect(response).to redirect_to("/users/sign_up")
        end
      end
    end
  end
end
