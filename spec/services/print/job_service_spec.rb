# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::JobService do
  subject(:service) { described_class.new(print_host: print_host, actor: actor, sdcp: sdcp) }

  let(:print_host) { create(:print_host, :with_capabilities) }
  let(:actor) { create(:admin) }
  let(:sdcp) { instance_double(Print::SdcpService) }
  let(:artifact) { create(:sliced_artifact, print_host: print_host, format: "ctb") }

  before do
    allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
  end

  describe "#create!" do
    it "creates a queued job when plate is clear" do
      job = service.create!(sliced_artifact: artifact, model: artifact.model)
      expect(job).to be_queued
      expect(job.user).to eq(actor)
      expect(job.estimated_resin_ml).to eq(artifact.estimated_resin_ml)
    end

    it "creates waiting_plate when prior success lacks plate_cleared_at" do
      create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      job = service.create!(sliced_artifact: artifact, model: artifact.model)
      expect(job).to be_waiting_plate
    end

    it "rejects unsupported stamp formats" do
      expect {
        service.create!(stamp: {format: "stl"}, model: artifact.model)
      }.to raise_error(Print::JobService::GateFailed)
    end
  end

  describe "#start! (REQ-006)" do
    let!(:job) { create(:print_job, print_host: print_host, sliced_artifact: artifact, state: :queued) }

    before do
      allow(sdcp).to receive(:start_print).and_return({"Ack" => 0})
    end

    it "rejects start without confirm: true" do
      expect {
        service.start!(job, confirm: false, filename: "part.ctb")
      }.to raise_error(Print::JobService::ConfirmationRequired)
      expect(sdcp).not_to have_received(:start_print)
    end

    it "rejects start when confirm is omitted/nil" do
      expect {
        service.start!(job, confirm: nil, filename: "part.ctb")
      }.to raise_error(Print::JobService::ConfirmationRequired)
    end

    it "starts when confirm: true and plate is clear" do
      service.start!(job, confirm: true, filename: "part.ctb")
      expect(job.reload).to be_printing
      expect(job.started_at).to be_present
      expect(sdcp).to have_received(:start_print).with(hash_including(filename: "part.ctb"))
    end

    it "rejects a second printing job on the same host" do
      create(:print_job, :printing, print_host: print_host)
      expect {
        service.start!(job, confirm: true, filename: "part.ctb")
      }.to raise_error(Print::JobService::Busy)
    end
  end

  describe "plate-cleared state machine (REQ-009, GR-002)" do
    it "blocks start while prior success lacks plate_cleared_at" do
      create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      waiting = create(:print_job, :waiting_plate, print_host: print_host, sliced_artifact: artifact)
      allow(sdcp).to receive(:start_print)

      expect {
        service.start!(waiting, confirm: true, filename: "next.ctb")
      }.to raise_error(Print::JobService::PlateNotCleared)
      expect(sdcp).not_to have_received(:start_print)
    end

    it "confirm_plate_cleared! promotes waiting_plate to queued without auto-start" do
      prior = create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: nil)
      waiting = create(:print_job, :waiting_plate, print_host: print_host, sliced_artifact: artifact)
      allow(sdcp).to receive(:start_print)

      service.confirm_plate_cleared!(prior)

      expect(prior.reload.plate_cleared_at).to be_present
      expect(waiting.reload).to be_queued
      expect(sdcp).not_to have_received(:start_print)
    end

    it "finalize! succeeded holds queued jobs as waiting_plate and never starts next" do
      printing = create(:print_job, :printing, print_host: print_host, sliced_artifact: artifact,
        estimated_resin_ml: 10)
      next_job = create(:print_job, print_host: print_host, sliced_artifact: artifact, state: :queued)
      allow(sdcp).to receive(:start_print)

      service.finalize!(printing, outcome: :succeeded)

      expect(printing.reload).to be_succeeded
      expect(printing.plate_cleared_at).to be_nil
      expect(printing.outcome).to eq("succeeded")
      expect(printing.finished_at).to be_present
      expect(next_job.reload).to be_waiting_plate
      expect(sdcp).not_to have_received(:start_print)
    end
  end

  describe "#finalize! history (REQ-008)" do
    let!(:printing) do
      create(:print_job, :printing, print_host: print_host, started_at: 30.minutes.ago,
        estimated_resin_ml: 12.5)
    end

    it "writes failure_note on failed outcome" do
      service.finalize!(printing, outcome: :failed, failure_note: "FEP tear")
      expect(printing.reload.failure_note).to eq("FEP tear")
      expect(printing.outcome).to eq("failed")
      expect(printing.actual_duration_seconds).to be >= 0
    end

    it "optionally decrements resin bottle by estimated ml" do
      bottle = create(:resin_bottle, print_host: print_host, remaining_ml: 100, capacity_ml: 1000)
      service.finalize!(printing, outcome: :succeeded, resin_bottle: bottle)
      expect(bottle.reload.remaining_ml).to eq(87.5)
    end
  end

  describe "pause / resume / cancel" do
    it "pauses a printing job" do
      job = create(:print_job, :printing, print_host: print_host)
      allow(sdcp).to receive(:pause_print).and_return({"Ack" => 0})
      service.pause!(job)
      expect(job.reload).to be_paused
    end

    it "resumes a paused job" do
      job = create(:print_job, print_host: print_host, state: :paused, started_at: Time.current)
      allow(sdcp).to receive(:continue_print).and_return({"Ack" => 0})
      service.resume!(job)
      expect(job.reload).to be_printing
    end

    it "cancels via stop when printing" do
      job = create(:print_job, :printing, print_host: print_host)
      allow(sdcp).to receive(:stop_print).and_return({"Ack" => 0})
      service.cancel!(job)
      expect(job.reload).to be_cancelled
      expect(job.outcome).to eq("cancelled")
    end
  end
end
