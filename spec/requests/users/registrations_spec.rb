require "rails_helper"

# cancel_user_registration GET    /users/cancel(.:format)                                                 users/registrations#cancel
#    new_user_registration GET    /users/sign_up(.:format)                                                users/registrations#new
#   edit_user_registration GET    /users/edit(.:format)                                                   users/registrations#edit
#        user_registration PATCH  /users(.:format)                                                        users/registrations#update
#                          PUT    /users(.:format)                                                        users/registrations#update
#                          DELETE /users(.:format)                                                        users/registrations#destroy
#                          POST   /users(.:format)                                                        users/registrations#create

RSpec.describe "Users::Registrations" do
  let(:old_password) { Faker::Internet.password max_length: 32, min_length: 32, mix_case: true, special_characters: true }
  let(:new_password) { Faker::Internet.password max_length: 32, min_length: 32, mix_case: true, special_characters: true }
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

  context "when in single user mode", :singleuser do
    context "when signed out" do
      describe "GET /users/sign_up" do
        it "raises an error" do
          get "/users/sign_up"
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "POST /users" do
        it "raises an error" do
          post "/users", params: post_options
          expect(response).to have_http_status(:forbidden)
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
          get "/users/cancel"
          expect(response).to have_http_status(:forbidden)
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

        it "remains on settings page" do
          expect(response).to redirect_to("/users/edit")
        end

        it "updates password" do
          expect(User.first.valid_password?(new_password)).to be true
        end
      end

      describe "DELETE /users" do
        it "raises an error" do
          delete "/users"
          expect(response).to have_http_status(:forbidden)
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
      allow(SiteSettings).to receive(:registration_enabled?).and_return(false)
    end

    context "when signed out" do
      describe "GET /users/sign_up" do
        it "raises an error" do
          get "/users/sign_up"
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "POST /users" do
        it "raises an error" do
          post "/users", params: post_options
          expect(response).to have_http_status(:forbidden)
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

        it "remains on settings page" do
          expect(response).to redirect_to("/users/edit")
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
      allow(SiteSettings).to receive(:registration_enabled?).and_return(true)
    end

    context "when signed out" do
      describe "GET /users/sign_up" do
        before { get "/users/sign_up" }

        it "shows signup page" do
          expect(response).to have_http_status(:success)
        end
      end

      describe "POST /users with approval disabled" do
        before {
          allow(SiteSettings).to receive(:approve_signups).and_return(false)
          allow(AltchaSolution).to receive(:verify_and_save).and_return(true)
          post "/users", params: post_options
        }

        it "creates a new user" do
          expect(User.count).to eq 2
        end

        it "creates user in approved state" do
          expect(User.last).to be_approved
        end

        it "redirects to welcome page" do
          expect(response).to redirect_to("/welcome")
        end

        it "signs in the user" do
          expect(controller.current_user&.username).to eq post_options[:user][:username]
        end
      end

      describe "POST /users with approval disabled and creator options, but with no creator slug" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        before {
          allow(SiteSettings).to receive_messages(
            approve_signups: false,
            autocreate_creator_for_new_users: true
          )
          allow(AltchaSolution).to receive(:verify_and_save).and_return(true)
        }

        let(:post_with_creator_options) {
          {
            user: {
              email: Faker::Internet.email,
              password: old_password,
              password_confirmation: old_password,
              creators_attributes: {
                "0" => {
                  name: Faker::Name.name,
                  slug: ""
                }
              }
            }
          }
        }
        let(:form_post) { post "/users", params: post_with_creator_options }

        it "doesn't create a new user" do
          expect { form_post }.not_to change(User, :count)
        end

        it "doesn't create a new creator" do
          expect { form_post }.not_to change(Creator, :count)
        end

        it "gives an unprocessable response" do
          form_post
          expect(response).to have_http_status :unprocessable_content
        end
      end

      describe "POST /users with approval disabled and creator options" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        before {
          allow(SiteSettings).to receive_messages(
            approve_signups: false,
            autocreate_creator_for_new_users: true
          )
          allow(AltchaSolution).to receive(:verify_and_save).and_return(true)
        }

        let(:post_with_creator_options) {
          {
            user: {
              email: Faker::Internet.email,
              password: old_password,
              password_confirmation: old_password,
              creators_attributes: {
                "0" => {
                  name: Faker::Name.name,
                  slug: Faker::Internet.username(specifier: 3, separators: [])
                }
              }
            }
          }
        }
        let(:form_post) { post "/users", params: post_with_creator_options }

        it "creates a new user" do
          expect { form_post }.to change(User, :count).by(1)
        end

        it "sets a username derived from the creator username" do
          form_post
          expect(controller.current_user&.username).to eq "u;" + post_with_creator_options.dig(:user, :creators_attributes, "0", :slug)
        end

        it "adds a Creator" do
          expect { form_post }.to change(Creator, :count).by(1)
        end

        it "adds a permission" do
          allow(SiteSettings).to receive(:default_viewer_role).and_return(nil)
          expect { form_post }.to change(Caber::Relation, :count).by(1)
        end

        it "sets up ownership relation with the Creator" do
          form_post
          expect(controller.current_user.creators.count).to eq 1
        end
      end

      describe "POST /users with approval enabled" do
        before {
          allow(SiteSettings).to receive(:approve_signups).and_return(true)
          allow(AltchaSolution).to receive(:verify_and_save).and_return(true)
          post "/users", params: post_options
        }

        it "creates a new user" do
          expect(User.count).to eq 2
        end

        it "creates user in pending state" do
          expect(User.last).not_to be_approved
        end

        it "redirects to root" do
          expect(response).to redirect_to("/")
        end

        it "does not sign in the user" do
          expect(controller.current_user).to be_nil
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
