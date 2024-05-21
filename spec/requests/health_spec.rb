require "rails_helper"

#  health GET    /health                                      health#index

RSpec.describe "Health" do
  context "when signed out" do
    describe "GET /health" do
      it "returns http success" do
        get "/health"
        expect(response).to have_http_status(:success)
      end

      it "does not redirect" do
        get "/health"
        expect(response).not_to redirect_to("/users/sign_in")
      end

      it "returns expected status response" do
        get "/health"
        expect(response.parsed_body["status"]).to eq("OK")
      end
    end
  end

  context "when signed in" do
    describe "GET /health" do
      it "returns http success" do
        get "/health"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
