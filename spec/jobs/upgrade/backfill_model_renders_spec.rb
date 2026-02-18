# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upgrade::BackfillModelRenders do
  subject(:job) { described_class.new }

  context "when building finder scope" do
    let!(:with) { create(:model_file, filename: "with.stl") }
    let!(:without) { create(:model_file, filename: "without.stl") }
    let!(:image) { create(:model_file, filename: "image.jpg") }

    before do
      with.attachment_data.store("derivatives", {"render" => {"id" => "dummy_value"}})
      with.save!
    end

    it "does not include model files with render derivative" do
      expect(job.scope).not_to include with
    end

    it "includes model files without render derivative" do
      expect(job.scope).to include without
    end

    it "does not include non-models" do
      expect(job.scope).not_to include image
    end
  end
end
