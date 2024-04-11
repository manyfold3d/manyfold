require "rails_helper"

#  new_user_password GET    /users/password/new(.:format)
# edit_user_password GET    /users/password/edit(.:format)
#      user_password PATCH  /users/password(.:format)
#                    PUT    /users/password(.:format)
#                    POST   /users/password(.:format)

RSpec.describe "Users::Passwords" do
  let(:new_password) { Faker::Internet.password min_length: 6, mix_case: true, special_characters: true }
  let(:reset_password_token) { SecureRandom.hex }
  let!(:admin) {
    create(:admin)
  }
  let(:post_options) {
    {
      user: {
        email: admin.email
      }
    }
  }
  let(:patch_options) {
    {
      user: {
        password: new_password,
        password_confirmation: new_password
      }
    }
  }

  context "when in single user mode" do
    context "when signed out" do
      describe "GET /users/password/new" do
        it "raises an error" do
          expect { get "/users/password/new" }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "POST /users/password" do
        it "raises an error" do
          expect { post "/users/password", params: post_options }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      describe "GET /users/password/edit" do
        it "redirects to sign in page" do
          get "/users/password/edit"
          expect(response).to redirect_to("/users/sign_in")
        end
      end

      describe "PATCH /users/password" do
        it "redirects to sign in page" do
          expect { patch "/users/password", params: patch_options }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end

    context "when signed in" do
      before { sign_in admin }

      describe "GET /users/password/new" do
        it "redirects to root" do
          get "/users/password/new"
          expect(response).to redirect_to("/")
        end
      end

      describe "POST /users/password" do
        it "redirects to root" do
          post "/users/password", params: post_options
          expect(response).to redirect_to("/")
        end
      end

      describe "GET /users/password/edit" do
        it "redirects to root" do
          get "/users/password/edit"
          expect(response).to redirect_to("/")
        end
      end

      describe "PATCH /users/password" do
        it "redirects to root" do
          patch "/users/password", params: patch_options
          expect(response).to redirect_to("/")
        end
      end
    end
  end

  context "when in multiuser mode", :multiuser do
    context "when signed out" do
      describe "GET /users/password/new" do
        it "shows the forgot password page" do
          get "/users/password/new"
          expect(response).to have_http_status(:success)
        end
      end

      describe "POST /users/password" do
        it "redirects to sign in page" do
          post "/users/password", params: post_options
          expect(response).to redirect_to("/users/sign_in")
        end

        it "sends a password reset email" do # rubocop:disable RSpec/ExampleLength
          expect {
            post "/users/password", params: post_options
          }.to send_email(
            from: "notifications@localhost",
            to: admin.email,
            subject: "Reset password instructions"
          )
        end
      end

      describe "GET /users/password/edit" do
        it "redirects to sign in page if the reset token isn't provided" do
          get "/users/password/edit"
          expect(response).to redirect_to("/users/sign_in")
        end

        it "shows the change password page if reset token is provided" do
          get "/users/password/edit", params: {reset_password_token: "abcdef"}
          expect(response).to have_http_status(:success)
        end
      end

      describe "PATCH /users/password" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:reset_token) {
          admin.send_reset_password_instructions
        }

        before do
          patch_options[:user][:reset_password_token] = reset_token
          patch "/users/password", params: patch_options
        end

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "changes the password" do
          admin.reload
          expect(admin.valid_password?(new_password)).to be true
        end
      end
    end

    context "when signed in" do
      before { sign_in admin }

      describe "GET /users/password/new" do
        it "redirects to root" do
          get "/users/password/new"
          expect(response).to redirect_to("/")
        end
      end

      describe "POST /users/password" do
        it "redirects to root" do
          post "/users/password", params: post_options
          expect(response).to redirect_to("/")
        end
      end

      describe "GET /users/password/edit" do
        it "redirects to root" do
          get "/users/password/edit"
          expect(response).to redirect_to("/")
        end
      end

      describe "PATCH /users/password" do
        it "redirects to root" do
          patch "/users/password", params: patch_options
          expect(response).to redirect_to("/")
        end
      end
    end
  end
end
