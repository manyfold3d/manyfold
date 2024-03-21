require "rails_helper"

#  uploads GET    /uploads(.:format)                                                      uploads#index
#          POST   /uploads(.:format)                                                      uploads#create

RSpec.describe "Uploads" do
  let(:admin) { create(:admin) }
  let(:library) { create(:library) }

  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    before { sign_in admin }

    describe "GET /uploads" do
      it "shows upload form" do
        get "/uploads"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /uploads" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "redirect back to index after upload" do
        post "/uploads", params: {post: {library_pick: library.id, scan_after_upload: "1"}, upload: {datafiles: []}}
        expect(response).to redirect_to("/libraries")
      end
    end
  end
end
