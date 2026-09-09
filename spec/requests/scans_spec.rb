require "rails_helper"

RSpec.describe "Scans" do
  describe "POST /scans" do
    let!(:library) do # rubocop:disable RSpec/LetSetup
      create(:library) do |l|
        create_list(:model, 2, library: l)
      end
    end

    context "when admin", :as_administrator do
      it "scans all libraries" do
        expect { post "/scans" }.to have_enqueued_job(Scan::Library::DetectFilesystemChangesJob).exactly(:once)
      end

      it "is allowed" do
        post "/scans"
        expect(response).to redirect_to("/models")
      end

      it "enqueues DedupLibraryJob once for type=dedup" do
        expect {
          post "/scans", params: {type: "dedup"}
        }.to have_enqueued_job(Scan::DedupLibraryJob).exactly(:once)
      end

      it "does not enqueue CheckAll or detect for type=dedup" do
        post "/scans", params: {type: "dedup"}
        expect(Scan::CheckAllJob).not_to have_been_enqueued
        expect(Scan::Library::DetectFilesystemChangesJob).not_to have_been_enqueued
      end

      it "redirects with the review-only dedup notice" do
        post "/scans", params: {type: "dedup"}
        expect(response).to redirect_to("/models")
        expect(flash[:notice]).to eq(I18n.t("scans.create.dedup_success"))
      end

      it "does not coerce an unknown type to check or dedup" do
        expect {
          post "/scans", params: {type: "not-a-real-scan-type"}
        }.to have_enqueued_job(Scan::Library::DetectFilesystemChangesJob).exactly(:once)
        expect(Scan::CheckAllJob).not_to have_been_enqueued
        expect(Scan::DedupLibraryJob).not_to have_been_enqueued
      end
    end

    it "is denied to mods and below", :as_moderator do
      post "/scans"
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids type=dedup for unauthorized users", :as_moderator do
      post "/scans", params: {type: "dedup"}
      expect(response).to have_http_status(:forbidden)
      expect(Scan::DedupLibraryJob).not_to have_been_enqueued
    end
  end
end
