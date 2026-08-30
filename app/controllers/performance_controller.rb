# frozen_string_literal: true

# INIT-013/SPEC-003 — Manyfold owns /admin/performance (HTML shell + KPI JSON).
# INIT-013/SPEC-004 — Phlex dashboard wired to Performance::Telemetry.
class PerformanceController < ApplicationController
  before_action { authorize :performance }

  after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: :index

  def index
    @telemetry = Performance::Telemetry.new.call
    @title = t(".title")

    respond_to do |format|
      format.html
      format.json { render json: telemetry_payload }
    end
  end

  private

  def telemetry_payload
    result = @telemetry
    {
      p50: result.p50,
      p95: result.p95,
      p99: result.p99,
      throughput: result.throughput,
      response_series: result.response_series,
      sample_count: result.sample_count,
      avg_db_ms: result.avg_db_ms,
      budget_exceeded: result.budget_exceeded
    }
  end
end
