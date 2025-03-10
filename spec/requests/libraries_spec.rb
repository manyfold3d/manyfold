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
        expect { post "/libraries/#{library.to_param}/scan" }.to have_enqueued_job(Scan::DetectFilesystemChangesJob).exactly(:once)
        expect(response).to redirect_to("/libraries/#{library.public_id}")
      end

      it "denies member permission", :as_member do
        post "/libraries/#{library.to_param}/scan"
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /libraries/scan" do
      it "scans all libraries", :as_contributor do # rubocop:todo RSpec/MultipleExpectations
        expect { post "/libraries/scan" }.to have_enqueued_job(Scan::DetectFilesystemChangesJob).exactly(:once)
        expect(response).to redirect_to("/models")
      end

      it "denies member permission", :as_member do
        post "/libraries/scan"
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /settings/libraries" do
      before { get "/settings/libraries" }

      it "denies permission", :as_member do
        expect(response).to have_http_status(:not_found)
      end

      it "shows list", :as_administrator do
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /libraries/" do
      before { post "/libraries", params: {library: {name: "new"}} }

      it "creates a new library", :as_administrator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-admins", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /libraries/new" do
      before { get "/libraries/new" }

      it "shows the new library form", :as_administrator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-admins", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /libraries/:id/edit" do
      before { get "/libraries/#{library.to_param}/edit" }

      it "shows the edit library form", :as_administrator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /libraries/:id" do
      it "redirects to models index with library filter", :as_member do
        get "/libraries/#{library.to_param}"
        expect(response).to redirect_to("/models?library=#{library.public_id}")
      end
    end

    describe "PATCH /libraries/:id" do
      before { patch "/libraries/#{library.to_param}", params: {library: {name: "new"}} }

      it "updates the library", :as_administrator do
        expect(response).to redirect_to("/models")
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /libraries/:id" do
      before { delete "/libraries/#{library.to_param}" }

      it "removes the library", :as_administrator do
        expect(response).to redirect_to("/settings/libraries")
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
