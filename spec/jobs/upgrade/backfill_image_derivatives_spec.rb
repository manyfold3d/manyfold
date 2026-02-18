# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upgrade::BackfillImageDerivatives do
  subject(:job) { described_class.new }

  context "when building finder scope" do
    let!(:with) { create(:model_file, filename: "with.jpg") }
    let!(:without) { create(:model_file, filename: "without.jpg") }
    let!(:model) { create(:model_file, filename: "model.stl") }

    before do
      with.attachment_data.store("derivatives", {"preview" => {"id" => "dummy_value"}})
      with.save!
    end

    it "does not include image files with preview derivative" do
      expect(job.scope).not_to include with
    end

    it "includes image files without preview derivative" do
      expect(job.scope).to include without
    end

    it "does not include non-images" do
      expect(job.scope).not_to include model
    end
  end
end
