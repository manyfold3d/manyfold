require "rails_helper"

RSpec.describe "Activities" do
  context "when logged in as admin", :as_administrator do
    describe "GET /" do
      it "returns http success" do
        allow(ActiveJob::Status).to receive(:all).and_return([])
        get "/activity"
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "when logged in as non-admin", :as_moderator do
    describe "GET /" do
      it "raises a routing error" do
        expect { get "/activity" }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
