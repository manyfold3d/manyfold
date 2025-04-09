require "rails_helper"

RSpec.describe "Uploads" do
  context "when signed out" do
    describe "POST /uploads" do
      it "is denied" do
        post "/uploads"
        expect(response).to have_http_status :not_found
      end
    end
  end

  context "when signed in" do
    describe "POST /uploads" do
      it "is denied to non-contributors", :as_member do
        post "/uploads"
        expect(response).to have_http_status :not_found
      end

      it "is OK for contributors", :as_contributor do
        pending "test does not yet work with authenticate block in routes.rb"
        post "/uploads"
        expect(response).to be_http_success
      end
    end
  end
end
