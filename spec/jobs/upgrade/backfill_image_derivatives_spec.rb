# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upgrade::BackfillImageDerivatives do
  subject(:job) { described_class.new }

  context "when building finder scope" do
    let!(:with) { create(:model_file, filename: "with.stl") }
    let!(:without) { create(:model_file, filename: "without.stl") }

    before do
      with.attachment_data["derivatives"] = {"preview" => {}}
      with.save!
    end

    it "does not include models with preview derivative" do
      expect(job.scope).not_to include with
    end

    it "includes models without preview derivative" do
      expect(job.scope).to include without
    end
  end
end
