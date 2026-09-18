require "rails_helper"

RSpec.describe "Follows", :after_first_run, :federated, :multiuser do
  context "when not logged in" do
    it "redirects to login before follow page is shown" do
      get "/follows/new"
      expect(response).to redirect_to "http://www.example.com/users/sign_in"
    end

    it "redirects to login before follow page alias is shown" do
      get "/authorize_interaction"
      expect(response).to redirect_to "http://www.example.com/users/sign_in"
    end
  end

  describe "POST /create" do
    it "should add a follow relationship for current user"
    it "should not add another follow relationship if one already exists"
  end

  describe "DELETE /" do
    it "should remove a follow relationship for current user"
    it "should work even if current user is not following target"
  end
end
