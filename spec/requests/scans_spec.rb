require "rails_helper"

RSpec.describe "Scans" do
  describe "POST /scans" do
    let!(:library) do # rubocop:disable RSpec/LetSetup
      create(:library) do |l|
        create_list(:model, 2, library: l)
      end
    end

    context "when contributor", :as_contributor do
      it "scans all libraries" do
        expect { post "/scans" }.to have_enqueued_job(Scan::Library::DetectFilesystemChangesJob).exactly(:once)
      end

      it "is allowed for contributors" do
        post "/scans"
        expect(response).to redirect_to("/models")
      end
    end

    it "denies member permission", :as_member do
      post "/scans"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
