# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PrintHistories API" do
  let(:print_host) { create(:print_host, :with_capabilities) }

  context "when signed in", :as_contributor do
    it "denies history" do
      get print_histories_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in", :as_administrator do
    it "filters history by date range and returns KPIs" do
      in_range = create(:print_job, :succeeded, print_host: print_host,
        finished_at: Time.zone.parse("2026-08-15 12:00:00"),
        plate_cleared_at: Time.current,
        actual_duration_seconds: 3600,
        actual_resin_ml: 100)
      create(:print_job, :failed, print_host: print_host,
        finished_at: Time.zone.parse("2026-07-01 12:00:00"))

      get print_histories_path, params: {from: "2026-08-01", to: "2026-08-31"}, as: :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      ids = body["histories"].map { |h| h["id"] }
      expect(ids).to include(in_range.id)
      expect(ids.length).to eq(1)
      expect(body.dig("kpis", "jobs")).to eq(1)
      expect(body.dig("kpis", "hours")).to eq(1.0)
    end
  end
end
