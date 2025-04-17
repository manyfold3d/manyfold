require "rails_helper"

#  user_settings GET    /users/:user_id/settings(.:format)                                      settings#show
#                PATCH  /users/:user_id/settings(.:format)                                      settings#update
#                PUT    /users/:user_id/settings(.:format)                                      settings#update

RSpec.describe "Settings" do
  context "when signed out" do
    describe "GET /settings" do
      it "returns access denied" do
        get "/settings"
        expect(response).to redirect_to("/users/sign_in")
      end
    end
  end

  context "when signed in", :as_contributor do
    describe "GET /settings" do
      it "returns not found" do
        get "/settings"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when signed in", :as_administrator do
    describe "GET /settings" do
      it "returns http success" do
        get "/settings"
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /settings" do
      it "redirects back to settings on success" do
        patch "/settings"
        expect(response).to redirect_to("/settings")
      end

      context "with folder settings params" do
        let(:params) {
          {
            folders: {
              model_path_template: "test/{tags}/{modelName}",
              parse_metadata_from_path: "1",
              safe_folder_names: "0"
            }
          }
        }

        before do
          SiteSettings.model_path_template = "before"
          SiteSettings.parse_metadata_from_path = false
          SiteSettings.safe_folder_names = true
          patch "/settings", params: params
        end

        it "saves path template" do
          expect(SiteSettings.model_path_template).to eq "test/{tags}/{modelName}"
        end

        it "saves parsing setting" do
          expect(SiteSettings.parse_metadata_from_path).to be true
        end

        it "saves safe folder name setting" do
          expect(SiteSettings.safe_folder_names).to be false
        end
      end

      context "with file settings params" do
        let(:params) {
          {
            files: {
              model_ignored_files: "/.*\\.lys/\n/.*\\.lyt/"
            }
          }
        }

        before do
          patch "/settings", params: params
        end

        it "saves file ignore regexes" do
          expect(SiteSettings.model_ignored_files).to eq [/.*\.lys/, /.*\.lyt/]
        end
      end
    end
  end
end
