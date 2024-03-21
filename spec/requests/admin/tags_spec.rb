require "rails_helper"

RSpec.describe "Admin::Tags" do
  it "is inaccessible to anything less than admin", :as_editor do
    get "/admin/acts_as_taggable_on_tags"
    expect(response).to have_http_status(:unauthorized)
  end

  context "with admin permission", :as_administrator do
    it "is accessible" do
      get "/admin/acts_as_taggable_on_tags"
      expect(response).to have_http_status(:success)
    end

    it "is inaccessible in demo mode" do
      Flipper.enable :demo_mode
      expect { get("/admin/acts_as_taggable_on_tags") }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
