require "rails_helper"

RSpec.describe "Plugins", :after_first_run do
  describe "GET /index" do
    it "returns http success", :as_administrator do
      get "/settings/plugins"
      expect(response).to have_http_status(:success)
    end
  end
end
