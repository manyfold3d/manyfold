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
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update assigning roles" do
    let(:user) { create(:user) }

    before do
      Role::ROLES.each do |r|
        Role.find_or_create_by name: r
      end
    end

    context "when administrator", :as_administrator do
      it "can grant admin permissions" do
        patch "/settings/users/#{user.to_param}",
          params: {user: {role_ids: [Role.find_by!(name: :administrator).id.to_s]}}
        expect(user.reload.is_administrator?).to be true
      end

      it "can grant moderator permissions" do
        patch "/settings/users/#{user.to_param}",
          params: {user: {role_ids: [Role.find_by!(name: :moderator).id.to_s]}}
        expect(user.reload.is_moderator?).to be true
      end
    end

    context "when moderator", :as_moderator do
      it "cannot grant admin permissions" do
        patch "/settings/users/#{user.to_param}",
          params: {user: {role_ids: [Role.find_by!(name: :administrator).id.to_s]}}
        expect(user.reload.is_administrator?).to be false
      end

      it "cannot grant moderator permissions" do
        patch "/settings/users/#{user.to_param}",
          params: {user: {role_ids: [Role.find_by!(name: :moderator).id.to_s]}}
        expect(user.reload.is_moderator?).to be false
      end

      it "cannot grant contributor permissions" do
        patch "/settings/users/#{user.to_param}",
          params: {user: {role_ids: [Role.find_by!(name: :contributor).id.to_s]}}
        expect(user.reload.is_contributor?).to be true
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
        expect(response).to have_http_status(:unprocessable_content)
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
