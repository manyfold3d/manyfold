require "rails_helper"
require "support/mock_directory"

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
