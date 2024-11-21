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

  describe "GET /edit", :as_moderator do
    let(:user) { create(:user) }

    it "renders a successful response" do
      get "/settings/users/#{user.to_param}/edit"
      expect(response).to be_successful
    end
  end
  describe "PATCH /update", :as_moderator do
    let(:user) { create(:user) }

    context "with valid parameters" do
      it "updates the requested user" do # rubocop:todo RSpec/MultipleExpectations
        attributes = attributes_for(:user)
        patch "/settings/users/#{user.to_param}", params: {user: attributes}
        user.reload
        expect(user.email).to eq attributes[:email]
        expect(user.username).to eq attributes[:username]
      end

      it "redirects to the user" do
        patch "/settings/users/#{user.to_param}", params: {user: attributes_for(:user)}
        user.reload
        expect(response).to redirect_to("/settings/users/#{user.to_param}")
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        patch "/settings/users/#{user.to_param}", params: {user: {email: "invalid"}}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end
