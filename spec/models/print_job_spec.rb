# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrintJob do
  let(:print_host) { create(:print_host) }

  describe "creating valid objects" do
    it "can be created with valid data" do
      job = create(:print_job, print_host: print_host)
      expect(job).to be_valid
      expect(job).to be_queued
    end

    it "requires a print_host" do
      expect(build(:print_job, print_host: nil)).not_to be_valid
    end

    it "allows optional model, model_file, and user" do
      model = create(:model)
      file = create(:model_file, model: model)
      user = create(:user)
      job = create(:print_job, print_host: print_host, model: model, model_file: file, user: user)
      expect(job.model).to eq(model)
      expect(job.model_file).to eq(file)
      expect(job.user).to eq(user)
    end
  end

  describe "states (INIT-008/SPEC-002)" do
    it "includes all manager states" do
      expect(described_class.states.keys).to match_array(
        %w[queued waiting_plate printing paused succeeded failed cancelled]
      )
    end

    %i[queued waiting_plate printing paused succeeded failed cancelled].each do |state|
      it "accepts state #{state}" do
        job = build(:print_job, print_host: print_host, state: state)
        expect(job).to be_valid
      end
    end

    it "rejects unknown states" do
      job = build(:print_job, print_host: print_host)
      job.state = "slicing"
      expect(job).not_to be_valid
      expect(job.errors[:state]).to be_present
    end
  end

  describe "one printing job per host (REQ-006)" do
    it "allows a single printing job" do
      expect(create(:print_job, :printing, print_host: print_host)).to be_valid
    end

    it "rejects a second printing job on the same host" do
      create(:print_job, :printing, print_host: print_host)
      second = build(:print_job, :printing, print_host: print_host)
      expect(second).not_to be_valid
      expect(second.errors[:state]).to be_present
    end

    it "allows printing on a different host" do
      create(:print_job, :printing, print_host: print_host)
      other = create(:print_host, endpoint: "http://10.0.0.200:3030", mainboard_id: "aabbccddeeff0011")
      expect(create(:print_job, :printing, print_host: other)).to be_valid
    end

    it "enforces uniqueness at the database via partial index" do
      create(:print_job, :printing, print_host: print_host)
      duplicate = build(:print_job, :printing, print_host: print_host)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "history fields (REQ-008)" do
    it "persists outcome, layers, durations, resin, and failure_note" do
      job = create(:print_job, :failed,
        print_host: print_host,
        layer_count: 800,
        estimated_duration_seconds: 3600,
        actual_duration_seconds: 900,
        estimated_resin_ml: 40.0,
        actual_resin_ml: 12.5,
        failure_note: "FEP tear")
      expect(job.history_outcome).to eq("failed")
      expect(job.layer_count).to eq(800)
      expect(job.estimated_duration_seconds).to eq(3600)
      expect(job.actual_duration_seconds).to eq(900)
      expect(job.estimated_resin_ml).to eq(40.0)
      expect(job.actual_resin_ml).to eq(12.5)
      expect(job.failure_note).to eq("FEP tear")
    end

    it "scopes history to terminal jobs" do
      succeeded = create(:print_job, :succeeded, print_host: print_host)
      create(:print_job, :printing, print_host: create(:print_host, endpoint: "http://10.0.0.201:3030", mainboard_id: "1122334455667788"))
      expect(described_class.history).to include(succeeded)
      expect(described_class.history.map(&:state)).to all(be_in(described_class::TERMINAL_STATES))
    end

    it "tracks plate_cleared_at for handshake" do
      job = create(:print_job, :succeeded, print_host: print_host, plate_cleared_at: Time.current)
      expect(job.plate_cleared_at).to be_present
    end
  end
end
