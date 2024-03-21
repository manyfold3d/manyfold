require "rails_helper"

#   scan_library POST   /libraries/:id/scan(.:format)                                           libraries#scan
# scan_libraries POST   /libraries/scan(.:format)                                               libraries#scan_all
#      libraries GET    /libraries(.:format)                                                    libraries#index
#                POST   /libraries(.:format)                                                    libraries#create
#    new_library GET    /libraries/new(.:format)                                                libraries#new
#   edit_library GET    /libraries/:id/edit(.:format)                                           libraries#edit
#        library GET    /libraries/:id(.:format)                                                libraries#show
#                PATCH  /libraries/:id(.:format)                                                libraries#update
#                PUT    /libraries/:id(.:format)                                                libraries#update
#                DELETE /libraries/:id(.:format)                                                libraries#destroy

RSpec.describe "Libraries" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    let!(:library) do
      create(:library) do |l|
        create_list(:model, 2, library: l)
      end
    end

    describe "POST /libraries/:id/scan" do
      it "scans a single library", :as_contributor do # rubocop:todo RSpec/MultipleExpectations
        expect { post "/libraries/#{library.id}/scan" }.to have_enqueued_job(Scan::DetectFilesystemChangesJob).exactly(:once)
        expect(response).to redirect_to("/libraries/#{library.id}")
      end
    end

    describe "POST /libraries/scan", :as_contributor do
      it "scans all libraries" do # rubocop:todo RSpec/MultipleExpectations
        expect { post "/libraries/scan" }.to have_enqueued_job(Scan::DetectFilesystemChangesJob).exactly(:once)
        expect(response).to redirect_to("/models")
      end
    end

    describe "GET /libraries", :as_viewer do
      it "redirects to models index" do
        get "/libraries"
        expect(response).to redirect_to("/models")
      end
    end

    describe "POST /libraries/", :as_editor do
      it "creates a new library" do
        post "/libraries", params: {library: {name: "new"}}
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/new", :as_editor do
      it "shows the new library form" do
        get "/libraries/new"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/:id/edit", :as_administrator do
      it "shows the edit library form" do
        get "/libraries/#{library.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/:id", :as_viewer do
      it "redirects to models index with library filter" do
        get "/libraries/#{library.id}"
        expect(response).to redirect_to("/models?library=#{library.id}")
      end
    end

    describe "PATCH /libraries/:id", :as_administrator do
      it "updates the library" do
        patch "/libraries/#{library.id}", params: {library: {name: "new"}}
        expect(response).to redirect_to("/models")
      end
    end

    describe "DELETE /libraries/:id", :as_administrator do
      it "removes the library" do
        delete "/libraries/#{library.id}"
        expect(response).to redirect_to("/libraries")
      end
    end
  end
end
