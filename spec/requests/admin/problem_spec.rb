require "rails_helper"

RSpec.describe "Admin::Problems" do
  it "is inaccessible to normal user" do
    sign_in create(:user)
    get "/admin/problems"
    expect(response).to have_http_status(:unauthorized)
  end

  context "with admin permission" do
    before do
      sign_in create(:admin)
    end

    it "is accessible" do
      get "/admin/problems"
      expect(response).to have_http_status(:success)
    end

    it "is inaccessible in demo mode" do
      Flipper.enable :demo_mode
      expect { get("/admin/problems") }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
