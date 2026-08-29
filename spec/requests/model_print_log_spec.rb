# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Model print log and send eligibility API" do
  let(:print_host) { create(:print_host, :with_capabilities) }
  let(:model) { create(:model) }

  context "when signed in", :as_contributor do
    it "denies model print log" do
      get model_print_log_path(model), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "returns model print log payload" do
      create(:sliced_artifact, model: model, print_host: print_host, format: "ctb")
      create(:print_job, :succeeded, model: model, print_host: print_host, plate_cleared_at: Time.current)

      get model_print_log_path(model), as: :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["sliced_artifacts"].length).to eq(1)
      expect(body["histories"].length).to eq(1)
      expect(body.dig("success_widget", "succeeded")).to eq(1)
    end

    it "does not offer STL for send eligibility" do
      stl = create(:model_file, model: model, filename: "part.stl")
      get send_eligibility_model_model_file_path(model, stl),
        params: {print_host_id: print_host.id}, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["eligible"]).to be(false)
      expect(body["offered"]).to be(false)
      expect(body["reasons"].first["code"]).to eq("format_not_sliced")
    end

    it "returns gate reasons for incompatible sliced file" do
      ctb = create(:model_file, model: model, filename: "part.ctb")
      get send_eligibility_model_model_file_path(model, ctb),
        params: {
          print_host_id: print_host.id,
          resolution_w: 100,
          resolution_h: 100
        }, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["eligible"]).to be(false)
      expect(body["reasons"].map { |r| r["code"] }).to include("resolution_mismatch")
    end

    it "marks compatible CTB as eligible" do
      ctb = create(:model_file, model: model, filename: "part.ctb")
      get send_eligibility_model_model_file_path(model, ctb),
        params: {
          print_host_id: print_host.id,
          resolution_w: print_host.resolution_w,
          resolution_h: print_host.resolution_h
        }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["eligible"]).to be(true)
      expect(response.parsed_body["offered"]).to be(true)
    end
  end
end
