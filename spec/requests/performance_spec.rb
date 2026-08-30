# frozen_string_literal: true

require "rails_helper"

# INIT-013/SPEC-003 — admin performance HTML shell + KPI JSON authz
# INIT-013/SPEC-004 — Phlex dashboard region markers / key copy
RSpec.describe "Admin performance" do
  describe "GET /admin/performance" do
    context "when signed out" do
      it "redirects to sign in" do
        get "/admin/performance"
        expect(response).to redirect_to("/users/sign_in")
      end

      it "rejects unauthenticated JSON" do
        get "/admin/performance.json"
        # Devise HTML → redirect; JSON/API-style → 401
        expect(response).to have_http_status(:unauthorized).or be_redirect
      end
    end

    context "when signed in as non-admin", :as_member do
      it "denies HTML access" do
        get "/admin/performance"
        # Devise admin constraint → 404; Pundit alone would be 403
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end

      it "denies JSON access" do
        get "/admin/performance.json"
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end
    end

    context "when signed in as administrator", :as_administrator do
      let(:telemetry_result) do
        Performance::Telemetry::Result.new(
          p50: 12.5,
          p95: 40.0,
          p99: 55.0,
          throughput: [{datetime: "20260830T0800", rpm: 2}],
          response_series: [{datetime: "20260830T0800", avg: 12.5}],
          sample_count: 3,
          avg_db_ms: 2.0,
          budget_exceeded: false
        )
      end

      before do
        telemetry = instance_double(Performance::Telemetry, call: telemetry_result)
        allow(Performance::Telemetry).to receive(:new).and_return(telemetry)
      end

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it "renders the Phlex dashboard regions and key copy" do
        get "/admin/performance"
        expect(response).to have_http_status(:success)
        body = response.body
        expect(body).to include('data-region="performance-dashboard"')
        expect(body).to include('data-region="performance-sidebar"')
        expect(body).to include('data-region="performance-kpi-row"')
        expect(body).to include('data-region="performance-charts"')
        expect(body).to include('data-region="performance-secondary"')
        expect(body).to include("Application Performance")
        expect(body).to include("Throughput Report")
        expect(body).to include("12.5 ms")
        # Manyfold primary tokens — not Figma indigo utility classes
        expect(body).to include("bg-primary-500")
        expect(body).not_to match(/class="[^"]*\b(bg|text)-indigo-\d+/)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it "returns KPI JSON from Performance::Telemetry" do
        get "/admin/performance.json"
        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to include(
          "p50" => 12.5,
          "p95" => 40.0,
          "p99" => 55.0,
          "sample_count" => 3,
          "avg_db_ms" => 2.0,
          "budget_exceeded" => false
        )
        expect(json["throughput"]).to eq([{"datetime" => "20260830T0800", "rpm" => 2}])
        expect(json["response_series"]).to eq([{"datetime" => "20260830T0800", "avg" => 12.5}])
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end
  end
end
