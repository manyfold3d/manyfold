require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::Model::ParseMetadataJob do
  context "with a simple model folder" do
    let(:model) { create(:model) }

    before do
      create(:model_file, model: model, filename: "part_1.lys")
      create(:model_file, model: model, filename: "part_2.obj")
    end

    it "sets the preview file to the first renderable scanned file by default" do
      expect { described_class.perform_now(model.id) }
        .to change { model.reload.preview_file&.filename }.to("part_2.obj")
    end

    it "queues up check for model problems once complete" do
      expect { described_class.perform_now(model.id) }
        .to have_enqueued_job(Scan::Model::CheckForProblemsJob).with(model.id).once
    end
  end

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
