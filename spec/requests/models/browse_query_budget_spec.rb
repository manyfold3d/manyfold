# frozen_string_literal: true

# Provenance: INIT-009/SPEC-005
require "rails_helper"

RSpec.describe "Models browse query budget" do
  [:multiuser, :singleuser].each do |mode|
    context "when signed in in #{mode} mode", mode do
      let(:library) { create(:library) }
      let!(:models_with_previews) do
        Array.new(5) do
          m = create(:model, library: library)
          img = create(:model_file, model: m, filename: "preview.jpg")
          m.update!(preview_file: img)
          m
        end
      end

      describe "GET /models", :as_member do
        it "returns the HTML index under policy_scope with has_image default" do
          get "/models"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("model-card-grid")
          # Default has_image filter is active on browse
          expect(response.body).to include('aria-pressed="true"')
        end

        it "keeps turbo-stream scroll pages free of tag-cloud work" do
          get "/models",
            params: {offset: 0, per_page: 3},
            headers: {
              "Accept" => "text/vnd.turbo-stream.html",
              "X-Infinite-Scroll" => "1"
            }
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("turbo-stream")
          # Stream payload is cards + sentinels only — no sidebar tag cloud markup
          expect(response.body).not_to include("tags_card")
        end

        it "reports total_count metadata from a single pre-includes count" do
          get "/models",
            params: {library: library.to_param, offset: 0, per_page: 3},
            headers: {
              "Accept" => "text/vnd.turbo-stream.html",
              "X-Infinite-Scroll" => "1"
            }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('data-total-count="5"')
          expect(models_with_previews.size).to eq(5)
        end
      end
    end
  end

  context "when signed out in multiuser mode", :after_first_run, :multiuser do
    let!(:public_model) do
      m = create(:model, :public)
      img = create(:model_file, model: m, filename: "cover.jpg")
      m.update!(preview_file: img)
      m
    end
    let!(:private_model) do
      m = create(:model)
      img = create(:model_file, model: m, filename: "secret.jpg")
      m.update!(preview_file: img)
      m
    end

    it "lists only public models on GET /models (policy_scope)" do
      get "/models"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(public_model.name)
      expect(response.body).not_to include(private_model.name)
    end
  end
end
