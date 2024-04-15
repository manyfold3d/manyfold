require "rails_helper"
require "support/mock_directory"

# edit_library_model_model_files GET    /libraries/:library_id/models/:model_id/model_files/edit(.:format)      model_files#bulk_edit
#      library_model_model_files PATCH  /libraries/:library_id/models/:model_id/model_files/update(.:format)    model_files#bulk_update
#                                POST   /libraries/:library_id/models/:model_id/model_files(.:format)           model_files#create
#  edit_library_model_model_file GET    /libraries/:library_id/models/:model_id/model_files/:id/edit(.:format)  model_files#edit
#       library_model_model_file GET    /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#show
#                                PATCH  /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#update
#                                PUT    /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#update
#                                DELETE /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#destroy

RSpec.describe "Model Files" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    let(:jpg_file) { create(:model_file, model: model, filename: "test.jpg") }
    let(:stl_file) { create(:model_file, model: model, filename: "test.stl") }
    let(:model) { create(:model, library: library, path: "model_one") }
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

    describe "GET /libraries/:library_id/models/:model_id/model_files/edit", :as_editor do
      it "shows bulk update form" do
        get bulk_edit_library_model_model_files_path(library, model, stl_file)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /libraries/:library_id/models/:model_id/model_files/update", :as_editor do
      it "bulk updates the files" do
        patch library_model_model_file_path(library, model, stl_file), params: {model_file: {name: "name"}}
        expect(response).to redirect_to(library_model_model_file_path(library, model, stl_file))
      end
    end

    describe "GET /libraries/:library_id/models/:model_id/model_files/:id/edit", :as_editor do
      it "shows edit page for file" do
        get edit_library_model_model_file_path(library, model, stl_file)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/:library_id/models/:model_id/model_files/:id", :as_viewer do
      describe "GET a model file in its original file format" do
        before do
          get library_model_model_file_path(library, model, stl_file, format: :stl)
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "has correct MIME type" do
          expect(response.media_type).to eq("model/stl")
        end
      end

      describe "GET an image file in its original file format", :as_viewer do
        before do
          get library_model_model_file_path(library, model, jpg_file, format: :jpg)
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "has correct MIME type" do
          expect(response.media_type).to eq("image/jpeg")
        end
      end
    end

    describe "POST /libraries/:library_id/models/:model_id/model_files", :as_editor do
      context "when requesting a conversion" do
        let(:params) { {convert: {id: stl_file.id, to: "threemf"}} }

        it "queues a conversion job" do
          expect { post library_model_model_files_path(library, model, params: params) }.to have_enqueued_job(Analysis::FileConversionJob).with(stl_file.id, :threemf)
        end

        it "redirects back to file list" do
          post library_model_model_files_path(library, model, params: params)
          expect(response).to redirect_to library_model_model_file_path(library, model, stl_file)
        end

        it "shows success message if conversion job was queued" do
          post library_model_model_files_path(library, model, params: params)
          follow_redirect!
          expect(response.body).to include "alert-info"
        end
      end

      it "shows an error with missing parameters" do
        post library_model_model_files_path(library, model, params: {})
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /libraries/:library_id/models/:model_id/model_files/:id", :as_editor do
      it "updates the file" do
        patch library_model_model_file_path(library, model, stl_file), params: {model_file: {name: "name"}}
        expect(response).to redirect_to(library_model_model_file_path(library, model, stl_file))
      end
    end

    describe "DELETE /libraries/:library_id/models/:model_id/model_files/:id", :as_editor do
      it "removes the file" do
        delete library_model_model_file_path(library, model, stl_file)
        expect(response).to redirect_to(library_model_path(library, model))
      end
    end
  end
end
