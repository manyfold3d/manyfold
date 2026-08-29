# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Print Studio queue / history / model log HTML", type: :request do
  context "when signed in as contributor", :as_contributor do
    it "denies the queue board HTML" do
      get print_jobs_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in as administrator", :as_administrator do
    let(:print_host) { create(:print_host, :with_capabilities, name: "Saturn 4 Ultra") }

    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "renders the job queue kanban with waiting badge and plate-cleared CTA" do
      artifact = create(:sliced_artifact, print_host: print_host, format: "ctb")
      create(:print_job, :waiting_plate, print_host: print_host, sliced_artifact: artifact)
      create(:print_job, :printing, print_host: print_host, model_file: create(:model_file, filename: "active.ctb"))
      succeeded = create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil,
        model_file: create(:model_file, filename: "done.ctb"))

      get print_jobs_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Job Queue")
      expect(response.body).to include("Waiting for plate clear confirmation")
      expect(response.body).to include("Confirm Plate Cleared")
      expect(response.body).to include(confirm_plate_cleared_print_job_path(succeeded))
      expect(response.body).to include(print_histories_path)
    end

    it "confirms plate cleared via HTML and redirects to the queue board" do
      artifact = create(:sliced_artifact, print_host: print_host, format: "ctb")
      succeeded = create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      waiting = create(:print_job, :waiting_plate, print_host: print_host, sliced_artifact: artifact)

      expect {
        post confirm_plate_cleared_print_job_path(succeeded)
      }.to change { succeeded.reload.plate_cleared_at }.from(nil)

      expect(response).to redirect_to(print_jobs_path)
      expect(waiting.reload).to be_queued
      expect(flash[:notice]).to eq(I18n.t("print_jobs.confirm_plate_cleared.success"))
    end

    it "renders print history with KPIs, failure detail, and date filter" do
      failed = create(:print_job, :failed, print_host: print_host,
        finished_at: Time.zone.parse("2026-08-15 12:00:00"),
        failure_note: "Detached from plate at layer 89")
      create(:print_job, :succeeded, print_host: print_host,
        finished_at: Time.zone.parse("2026-08-16 12:00:00"),
        plate_cleared_at: Time.current,
        actual_duration_seconds: 3600,
        actual_resin_ml: 100)

      get print_histories_path, params: {from: "2026-08-01", to: "2026-08-31"}
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Print History")
      expect(response.body).to include("Total Prints")
      expect(response.body).to include("Show failure detail")
      expect(response.body).to include(failed.failure_note)
      expect(response.body).to include("Export CSV")
    end

    it "renders model print log with artifacts, success widget, and slicer stub" do
      model = create(:model, name: "Dragon Bust")
      create(:sliced_artifact, model: model, print_host: print_host, format: "ctb",
        model_file: create(:model_file, model: model, filename: "dragon.ctb"))
      create(:print_job, :succeeded, model: model, print_host: print_host, plate_cleared_at: Time.current)
      create(:print_job, :failed, model: model, print_host: print_host)

      get model_print_log_path(model)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dragon Bust")
      expect(response.body).to include("ctb")
      expect(response.body).to include("1/2 prints successful")
      expect(response.body).to include("Open in Slicer")
      expect(response.body).to include("Print")
    end

    it "routes nav Queue to the job board for administrators" do
      get printers_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('href="' + print_jobs_path)
    end
  end
end
