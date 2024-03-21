require "rails_helper"

RSpec.describe "Admin::Delayed_Job" do
  it "is inaccessible to anything less than admin", :as_editor do
    get "/admin/delayed_backend_active_record_jobs"
    expect(response).to have_http_status(:unauthorized)
  end

  context "with admin permission", :as_administrator do
    it "is accessible" do
      get "/admin/delayed_backend_active_record_jobs"
      expect(response).to have_http_status(:success)
    end

    it "is inaccessible in demo mode" do
      Flipper.enable :demo_mode
      expect { get("/admin/delayed_backend_active_record_jobs") }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
