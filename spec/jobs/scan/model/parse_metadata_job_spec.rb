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

  context "when generating tags from folder name" do
    before do
      allow(SiteSettings).to receive_messages(
        model_tags_tag_model_directory_name: true,
        parse_metadata_from_path: false,
        model_tags_auto_tag_new: nil
      )
    end

    context "without stop word filtering" do
      before do
        allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
      end

      it "skips single letter tags" do
        model = create(:model, path: "/library1/stuff/a")
        described_class.perform_now(model.id)
        expect(model.tag_list).to eq []
      end

      it "generates tag from whitespace delimited file names" do
        model = create(:model, path: "/library1/stuff/this is a fantasy model", tags: [])
        described_class.perform_now(model.id)
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from underscore delimited file names" do
        model = create(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        described_class.perform_now(model.id)
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from plus delimited file names" do
        model = create(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        described_class.perform_now(model.id)
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from hyphen delimited file names" do
        model = create(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        described_class.perform_now(model.id)
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end
    end
  end
end
