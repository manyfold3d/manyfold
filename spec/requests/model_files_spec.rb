require "rails_helper"
require "support/mock_directory"

# edit_library_model_model_files GET    /libraries/:library_id/models/:model_id/model_files/edit(.:format)      model_files#bulk_edit
#      library_model_model_files PATCH  /libraries/:library_id/models/:model_id/model_files/update(.:format)    model_files#bulk_update
#                                POST   /libraries/:library_id/models/:model_id/model_files(.:format)           model_files#create
#   new_library_model_model_file GET    /libraries/:library_id/models/:model_id/model_files/new(.:format)       model_files#new
#  edit_library_model_model_file GET    /libraries/:library_id/models/:model_id/model_files/:id/edit(.:format)  model_files#edit
#       library_model_model_file GET    /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#show
#                                PATCH  /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#update
#                                PUT    /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#update
#                                DELETE /libraries/:library_id/models/:model_id/model_files/:id(.:format)       model_files#destroy

RSpec.describe "Model Files" do
  before do
    sign_in create(:user)
  end

  around do |ex|
    MockDirectory.create([
      "model_one/test.stl",
      "model_one/test.jpg"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
  let(:model) { create(:model, library: library, path: "model_one") }
  let(:stl_file) { create(:model_file, model: model, filename: "test.stl") }
  let(:jpg_file) { create(:model_file, model: model, filename: "test.jpg") }

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

  describe "GET an image file in its original file format" do
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
