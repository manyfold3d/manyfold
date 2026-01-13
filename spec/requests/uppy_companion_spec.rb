require "rails_helper"

invalid_urls = [
  nil,
  "",
  "ftp://url.myendpoint.com/files"
]

RSpec.describe "UppyCompanion" do
  describe "POST /uppy_companion/url/meta" do
    let(:valid_post) do
      post "/uppy_companion/url/meta", params: {url: "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg"}.to_json, headers: {Accept: "application/json", "Content-Type": "application/json"}
    end

    it "returns unauthorized if user isn't authenticated" do
      valid_post
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not found if user doesn't have permission", :as_member do
      valid_post
      expect(response).to have_http_status(:not_found)
    end

    context "with valid URL", :as_contributor, vcr: {cassette_name: "UppyCompanion_meta_success"} do
      before { valid_post }

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns JSON" do
        expect(response.content_type).to include "application/json"
      end

      it "gets filename" do
        expect(response.parsed_body["name"]).to eq "Example.jpg"
      end

      it "gets size" do
        expect(response.parsed_body["size"]).to eq 9022
      end

      it "gets content type" do
        expect(response.parsed_body["type"]).to eq "image/jpeg"
      end

      it "gets remote status code" do
        expect(response.parsed_body["status_code"]).to eq 200
      end
    end

    invalid_urls.each do |url|
      it "flags bad request for invalid URL #{url.inspect}", :as_contributor do
        post "/uppy_companion/url/meta", params: {url: url}.to_json, headers: {Accept: "application/json", "Content-Type": "application/json"}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "POST /uppy_companion/url/get" do
    let(:valid_post) do
      post "/uppy_companion/url/get", params: {url: "https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg"}.to_json, headers: {Accept: "application/json", "Content-Type": "application/json"}
    end

    it "returns unauthorized if user isn't authenticated" do
      valid_post
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not found if user doesn't have permission", :as_member do
      valid_post
      expect(response).to have_http_status(:not_found)
    end

    context "with valid URL", :as_contributor, vcr: {cassette_name: "UppyCompanion_get_success"} do
      before { valid_post }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end

    invalid_urls.each do |url|
      it "flags bad request for invalid URL #{url.inspect}", :as_contributor do
        post "/uppy_companion/url/get", params: {url: url}.to_json, headers: {Accept: "application/json", "Content-Type": "application/json"}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
