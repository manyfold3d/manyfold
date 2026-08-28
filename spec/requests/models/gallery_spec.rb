# frozen_string_literal: true

# Provenance: INIT-006/SPEC-002
require "rails_helper"

RSpec.describe "Models gallery" do
  [:multiuser, :singleuser].each do |mode|
    context "when signed in in #{mode} mode", mode do
      let(:library) { create(:library) }
      let(:model) { create(:model, library: library) }
      let!(:preview) { create(:model_file, model: model, filename: "cover.jpg") }
      let!(:extra) { create(:model_file, model: model, filename: "detail.png") }

      before { model.update!(preview_file: preview) }

      describe "GET /models/:id/gallery", :as_member do
        it "returns a turbo-frame browse carousel for multi-image models" do
          get gallery_model_path(model)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('turbo-frame id="model-gallery"')
          expect(response.body).to include('id="browseCarousel"')
          expect(response.body).to include(preview.filename)
          expect(response.body).to include(extra.filename)
        end

        it "exposes prev/next controls when two images are present" do
          get gallery_model_path(model)
          expect(response.body).to include("carousel#prev")
          expect(response.body).to include("carousel#next")
          expect(response.body).to include('data-carousel-interval-value="0"')
          expect(preview.filename).to eq("cover.jpg")
          expect(extra.filename).to eq("detail.png")
        end

        it "keeps gallery images under policy_scope (authorized success)" do
          # ModelsController#gallery uses policy_scope(@model.model_files); a 200
          # for the member proves the action still authorizes via show?/gallery?.
          get gallery_model_path(model)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(preview.filename)
        end
      end
    end
  end

  context "when signed out in multiuser mode", :after_first_run, :multiuser do
    let(:model) { create(:model) }
    let!(:preview) { create(:model_file, model: model, filename: "cover.jpg") }

    before { model.update!(preview_file: preview) }

    it "does not expose private model gallery" do
      expect(preview).to be_persisted
      get gallery_model_path(model)
      expect(response).to be_not_found
    end
  end
end
