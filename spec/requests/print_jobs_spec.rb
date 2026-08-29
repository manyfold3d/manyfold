# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PrintJobs API" do
  let(:print_host) { create(:print_host, :with_capabilities) }
  let(:artifact) { create(:sliced_artifact, print_host: print_host, format: "ctb") }
  let(:sdcp) { instance_double(Print::SdcpService) }

  context "when signed in", :as_contributor do
    it "denies queue board" do
      get print_jobs_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
      allow(Print::SdcpService).to receive(:new).and_return(sdcp)
      allow(sdcp).to receive(:start_print).and_return({"Ack" => 0})
      allow(sdcp).to receive(:pause_print).and_return({"Ack" => 0})
      allow(sdcp).to receive(:continue_print).and_return({"Ack" => 0})
      allow(sdcp).to receive(:stop_print).and_return({"Ack" => 0})
    end

    it "returns queue board columns" do
      create(:print_job, print_host: print_host, state: :queued)
      create(:print_job, :printing, print_host: print_host)
      create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: Time.current)

      get print_jobs_path, as: :json
      expect(response).to have_http_status(:success)
      queue = response.parsed_body["queue"]
      expect(queue["queued"].length).to eq(1)
      expect(queue["printing"].length).to eq(1)
      expect(queue["completed"].length).to eq(1)
    end

    it "creates a job and returns 422 with gate reasons for STL stamp" do
      post print_jobs_path, params: {
        print_job: {
          print_host_id: print_host.id,
          stamp: {format: "stl"}
        }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      body = response.parsed_body
      expect(body["error"]).to eq("gate_failed")
      expect(body["reasons"].map { |r| r["code"] }).to include("format_unsupported")
    end

    it "creates a queued job when gate passes" do
      expect {
        post print_jobs_path, params: {
          print_job: {
            print_host_id: print_host.id,
            sliced_artifact_id: artifact.id
          }
        }, as: :json
      }.to change(PrintJob, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("print_job", "state")).to eq("queued")
    end

    it "requires confirm to start and blocks until plate cleared" do
      job = create(:print_job, print_host: print_host, sliced_artifact: artifact, state: :queued)

      post start_print_job_path(job), params: {confirm: false}, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("confirmation_required")

      create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      post start_print_job_path(job), params: {confirm: true, filename: "part.ctb"}, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("plate_not_cleared")
    end

    it "starts with confirm when plate is clear, then pause/resume/cancel" do
      job = create(:print_job, print_host: print_host, sliced_artifact: artifact, state: :queued)

      post start_print_job_path(job), params: {confirm: true, filename: "part.ctb"}, as: :json
      expect(response).to have_http_status(:success)
      expect(job.reload).to be_printing

      post pause_print_job_path(job), as: :json
      expect(job.reload).to be_paused

      post resume_print_job_path(job), as: :json
      expect(job.reload).to be_printing

      post cancel_print_job_path(job), as: :json
      expect(job.reload).to be_cancelled
    end

    it "confirms plate cleared and promotes waiting jobs without auto-start" do
      succeeded = create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      waiting = create(:print_job, :waiting_plate, print_host: print_host, sliced_artifact: artifact)

      post confirm_plate_cleared_print_job_path(succeeded), as: :json
      expect(response).to have_http_status(:success)
      expect(succeeded.reload.plate_cleared_at).to be_present
      expect(waiting.reload).to be_queued
      expect(sdcp).not_to have_received(:start_print)
    end
  end
end
