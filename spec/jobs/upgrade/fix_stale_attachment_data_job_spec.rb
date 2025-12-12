# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upgrade::FixStaleAttachmentDataJob do
  subject(:job) { described_class.new }

  context "when building finder scope" do
    let!(:good) { create(:model_file, filename: "good.stl") }
    let!(:bad) { create(:model_file, filename: "bad.stl") }

    before do
      bad.attachment_data.store("storage", "cache")
      bad.save!
    end

    it "does not include models in proper storage" do
      expect(job.scope).not_to include good
    end

    it "includes models in cache storage" do
      expect(job.scope).to include bad
    end
  end

  context "when fixing bad data" do
    let!(:bad) { create(:model_file, filename: "bad.stl") }

    before do
      bad.attachment_data.store("id", ".manyfold/error.stl")
      bad.attachment_data.store("storage", "cache")
      bad.save!
    end

    it "fixes storage key" do
      expect { job.perform_now }.to change { bad.reload.attachment.storage_key }.from(:cache).to(:library_1)
    end

    it "fixes attachment id" do
      expect { job.perform_now }.to change { bad.reload.attachment.id }.from(".manyfold/error.stl").to("#{bad.model.path}/bad.stl")
    end
  end
end
