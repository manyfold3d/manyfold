require "rails_helper"
require "support/mock_directory"

# edit_model_model_files GET    /models/:model_id/model_files/edit(.:format)      model_files#bulk_edit
#      model_model_files PATCH  /models/:model_id/model_files/update(.:format)    model_files#bulk_update
#                        POST   /models/:model_id/model_files(.:format)           model_files#create
#  edit_model_model_file GET    /models/:model_id/model_files/:id/edit(.:format)  model_files#edit
#       model_model_file GET    /models/:model_id/model_files/:id(.:format)       model_files#show
#                        PATCH  /models/:model_id/model_files/:id(.:format)       model_files#update
#                        PUT    /models/:model_id/model_files/:id(.:format)       model_files#update
#                        DELETE /models/:model_id/model_files/:id(.:format)       model_files#destroy

RSpec.describe "Model Files" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    let!(:jpg_file) { create(:model_file, model: model, filename: "test.jpg") }
    let!(:stl_file) { create(:model_file, model: model, filename: "test.stl") }
    let!(:model) { create(:model, library: library, path: "model_one") }
    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    around do |ex|
      MockDirectory.create([
        "model_one/test.stl",
        "model_one/test.jpg"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    describe "GET /models/:model_id/model_files/edit", :as_moderator do
      it "shows bulk update form" do
        get bulk_edit_model_model_files_path(model)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /models/:model_id/model_files/update", :as_moderator do
      let(:params) do
        {
          model_files: {stl_file.public_id => "1", jpg_file.public_id => "0"},
          y_up: "1",
          printed: "1",
          presupported: "1"
        }
      end

      it "bulk updates Y Up on the selected files" do
        patch bulk_update_model_model_files_path(model, params: params)
        expect(stl_file.reload.y_up).to be_truthy
      end

      it "bulk updates presupported flag on the selected files" do
        patch bulk_update_model_model_files_path(model, params: params)
        expect(stl_file.reload.presupported).to be_truthy
      end

      it "bulk updates printed flag on the selected files" do
        patch bulk_update_model_model_files_path(model, params: params)
        expect(stl_file.listers(:printed)).to include controller.current_user
      end

      it "does not modify non-selected files" do
        patch bulk_update_model_model_files_path(model, params: params)
        expect(jpg_file.reload.y_up).to be_falsy
      end

      it "splits model" do
        expect {
          patch bulk_update_model_model_files_path(model, params: params.merge(split: "split"))
        }.to change(Model, :count).by(1)
      end
    end

    describe "GET /models/:model_id/model_files/:id/edit", :as_moderator do
      it "shows edit page for file" do
        get edit_model_model_file_path(model, stl_file)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /models/:model_id/model_files/:id", :as_member do
      describe "GET a model file in its original file format" do
        before do
          get model_model_file_path(model, stl_file, format: :stl)
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "has correct MIME type" do
          expect(response.media_type).to eq("model/stl")
        end
      end

      describe "GET an image file in its original file format", :as_member do
        before do
          get model_model_file_path(model, jpg_file, format: :jpg)
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "has correct MIME type" do
          expect(response.media_type).to eq("image/jpeg")
        end
      end
    end

    describe "POST /models/:model_id/model_files", :as_moderator do
      context "when requesting a conversion" do
        let(:params) { {convert: {id: stl_file.to_param, to: "threemf"}} }

        it "queues a conversion job" do
          expect { post model_model_files_path(model, params: params) }.to have_enqueued_job(Analysis::FileConversionJob).with(stl_file.id, :threemf)
        end

        it "redirects back to file list" do
          post model_model_files_path(model, params: params)
          expect(response).to redirect_to model_model_file_path(model, stl_file)
        end

        it "shows success message if conversion job was queued" do
          post model_model_files_path(model, params: params)
          follow_redirect!
          expect(response.body).to include "alert-info"
        end
      end

      it "shows an error with missing parameters" do
        post model_model_files_path(model, params: {})
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /models/:model_id/model_files/:id", :as_moderator do
      it "updates the file" do
        patch model_model_file_path(model, stl_file), params: {model_file: {name: "name"}}
        expect(response).to redirect_to(model_model_file_path(model, stl_file))
      end
    end

    describe "DELETE /models/:model_id/model_files/:id", :as_moderator do
      it "removes the file" do
        delete model_model_file_path(model, stl_file)
        expect(response).to redirect_to(model_path(model))
      end
    end
  end
end
