require 'rails_helper'

RSpec.describe "UppyCompanions", type: :request do
  describe "GET /url_meta" do
    it "returns http success" do
      get "/uppy_companion/url_meta"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /url_get" do
    it "returns http success" do
      get "/uppy_companion/url_get"
      expect(response).to have_http_status(:success)
    end
  end

end
