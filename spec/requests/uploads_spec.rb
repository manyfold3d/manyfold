require "rails_helper"

#  uploads GET    /uploads(.:format)                                                      uploads#index
#          POST   /uploads(.:format)                                                      uploads#create

RSpec.describe "Uploads" do
  let(:library) { create(:library) }

  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    describe "GET /uploads" do
      it "shows upload form", :as_contributor do
        get "/uploads"
        expect(response).to have_http_status(:success)
      end

      it "denies viewer permission", :as_viewer do
        expect { get "/uploads" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /uploads" do
      it "redirect back to index after upload", :as_contributor do
        post "/uploads", params: {post: {library_pick: library.id, scan_after_upload: "1"}, upload: {datafiles: []}}
        expect(response).to redirect_to("/libraries")
      end

      it "denies viewer permission", :as_viewer do
        expect { post "/uploads", params: {post: {library_pick: library.id, scan_after_upload: "1"}, upload: {datafiles: []}} }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
