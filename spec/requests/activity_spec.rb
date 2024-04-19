require "rails_helper"

RSpec.describe "Activities", type: :request do
  context "as admin", :as_administrator do
    describe "GET /" do
      it "returns http success" do
        get "/activity"
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "as non-admin", :as_editor do
    describe "GET /" do
      it "raises a routing error" do
        expect { get "/activity" }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
