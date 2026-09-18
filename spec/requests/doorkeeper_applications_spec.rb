require "rails_helper"

RSpec.describe "OAuth applications", :after_first_run, :multiuser do
  context "when logged in as moderator", :as_moderator do
    describe "GET /oauth/applications" do
      it "succeeds" do
        get "/oauth/applications"
        expect(response).to have_http_status :success
      end
    end

    describe "GET /oauth/applications/{id}" do
      it "can view apps owned by other users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        get "/oauth/applications/#{app.to_param}"
        expect(response).to have_http_status :success
      end

      it "cannot view apps owned by admins" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        get "/oauth/applications/#{app.to_param}"
        expect(response).to have_http_status :forbidden
      end
    end

    describe "GET /oauth/applications/{id}/edit" do
      it "can edit apps owned by other users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        get "/oauth/applications/#{app.to_param}/edit"
        expect(response).to have_http_status :success
      end

      it "cannot edit apps owned by admins" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        get "/oauth/applications/#{app.to_param}/edit"
        expect(response).to have_http_status :forbidden
      end
    end

    describe "DELETE /oauth/applications/{id}" do
      it "can delete apps owned by other users" do
        app = Doorkeeper::Application.create! owner: create(:contributor), name: "test app"
        delete "/oauth/applications/#{app.to_param}"
        expect(response).to redirect_to "http://www.example.com/oauth/applications"
      end

      it "cannot delete apps owned by admins" do
        app = Doorkeeper::Application.create! owner: create(:admin), name: "test app"
        delete "/oauth/applications/#{app.to_param}"
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
