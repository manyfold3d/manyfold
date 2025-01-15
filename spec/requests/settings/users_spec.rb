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

  describe "GET /new", :as_moderator do
    it "renders a successful response" do
      get new_settings_user_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit", :as_moderator do
    let(:user) { create(:user) }

    it "renders a successful response" do
      get "/settings/users/#{user.to_param}/edit"
      expect(response).to be_successful
    end
  end

  describe "POST /create", :as_moderator do
    context "with valid parameters" do
      it "creates a new Settings::User" do
        attributes = attributes_for(:user)
        attributes[:password_confirmation] = attributes[:password]
        expect {
          post "/settings/users", params: {user: attributes}
        }.to change(User, :count).by(1)
      end

      it "redirects to the created user" do
        attributes = attributes_for(:user)
        attributes[:password_confirmation] = attributes[:password]
        post "/settings/users", params: {user: attributes}
        expect(response).to redirect_to(settings_user_url(User.last))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { {email: "invalid"} }

      it "does not create a new Settings::User" do
        expect {
          post "/settings/users", params: {user: invalid_attributes}
        }.not_to change(User, :count)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post "/settings/users", params: {user: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update", :as_moderator do
    let(:user) { create(:user) }

    context "with valid parameters" do
      let(:attributes) { attributes_for(:user) }

      it "updates the requested user" do # rubocop:todo RSpec/MultipleExpectations
        patch "/settings/users/#{user.to_param}", params: {user: attributes}
        user.reload
        expect(user.email).to eq attributes[:email]
        expect(user.username).to eq attributes[:username]
      end

      it "redirects to the user" do
        patch "/settings/users/#{user.to_param}", params: {user: attributes}
        user.reload
        expect(response).to redirect_to("/settings/users/#{user.to_param}")
      end
    end

    context "with invalid parameters" do
      let(:attributes) { {email: "invalid"} }

      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        patch "/settings/users/#{user.to_param}", params: {user: attributes}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with password reset parameter" do
      it "sets a reset token" do
        patch "/settings/users/#{user.to_param}", params: {reset: true}
        user.reload
        expect(user.reset_password_token).to be_present
      end

      it "returns to user page" do
        patch "/settings/users/#{user.to_param}", params: {reset: true}
        expect(response).to redirect_to("/settings/users/#{user.to_param}")
      end
    end
  end
end
