require "rails_helper"

RSpec.describe "PrintHosts", :after_first_run do
  context "when signed out" do
    it "sends logged-out users to login" do
      get "/print_hosts"
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  context "when signed in" do
    let!(:print_host) { create(:print_host) }

    describe "GET /print_hosts" do
      before { get "/print_hosts" }

      it "denies permission to anyone below admin", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end

      it "shows list to admins", :as_administrator do
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /print_hosts/" do
      before { post "/print_hosts", params: {print_host: attributes_for(:print_host)} }

      it "creates a new print host", :as_administrator do
        expect(response).to redirect_to("/print_hosts")
      end

      it "is denied to non-admins", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /print_hosts/new" do
      before { get "/print_hosts/new" }

      it "shows the new print host form", :as_administrator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-admins", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /print_hosts/:id/edit" do
      before { get "/print_hosts/#{print_host.to_param}/edit" }

      it "shows the edit print host form", :as_administrator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "PATCH /print_hosts/:id" do
      before { patch "/print_hosts/#{print_host.to_param}", params: {print_host: {name: "changed", credentials: "passw0rd"}} }

      it "redirects back to list afterwards", :as_administrator do
        expect(response).to redirect_to("/print_hosts")
      end

      it "updates credentials", :as_administrator do
        expect(print_host.reload.credentials).to eq "passw0rd"
      end

      it "updates name", :as_administrator do
        expect(print_host.reload.name).to eq "changed"
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /print_hosts/:id" do
      before do
        delete "/print_hosts/#{print_host.to_param}"
      end

      it "removes the print host", :as_administrator do
        expect(response).to redirect_to("/print_hosts")
      end

      it "is denied to non-administrators", :as_moderator do
        expect(response).to have_http_status(:forbidden)
      end

      it "denies permission to people with print-only permissions", :as_printer do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /print_hosts/:id/print" do
      let(:file) { create(:model_file) }

      context "when the user has access to the file", :as_administrator do
        it "redirects back to file by default" do
          post "/print_hosts/#{print_host.to_param}/print", params: {file_id: file.public_id}
          expect(response).to redirect_to(model_model_file_path(file.model, file))
        end

        it "starts print job" do
          expect {
            post "/print_hosts/#{print_host.to_param}/print", params: {file_id: file.public_id}
          }.to have_enqueued_job(SendFileToPrintHostJob).with(print_host: print_host, file: file)
        end
      end

      it "is denied to non-administrators", :as_moderator do
        post "/print_hosts/#{print_host.to_param}/print", params: {file_id: file.public_id}
        expect(response).to have_http_status(:forbidden)
      end

      it "accepts print requests from people with print-only permissions", :as_printer do
        expect {
          post "/print_hosts/#{print_host.to_param}/print", params: {file_id: file.public_id}
        }.to have_enqueued_job(SendFileToPrintHostJob).with(print_host: print_host, file: file)
      end
    end
  end
end
