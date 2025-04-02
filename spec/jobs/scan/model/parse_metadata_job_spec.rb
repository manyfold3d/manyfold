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

    context "with stop word filtering" do
      before do
        allow(SiteSettings).to receive_messages(
          model_tags_stop_words_locale: "en",
          model_tags_filter_stop_words: true,
          model_tags_custom_stop_words: ["chicken"]
        )
      end

      it "generates tags and filters custom stop words" do
        model = create(:model, path: "/library1/stuff/this-is-a-scifi-chicken-model")
        described_class.perform_now(model.id)
        expect(model.reload.tag_list).to eq ["scifi", "model"]
      end
    end
  end

  context "when parsing metadata from a path template" do
    before do
      allow(SiteSettings).to receive_messages(
        model_tags_tag_model_directory_name: false,
        parse_metadata_from_path: true,
        model_tags_auto_tag_new: nil,
      )
    end

    let(:model) { create(:model, path: "/top/middle/bottom/prefix - name#42") }

    {
      "{tags}" => %r{^/?.*?(?<tags>[[:print:]]*)$},
      "{creator}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)$},
      "{collection}" => %r{^/?.*?(?<collection>[[:print:]&&[^/]]*?)$},
      "{tags}/{creator}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)$},
      "{tags}/{creator}/{modelName}{modelId}" => %r{^/?.*?(?<tags>[[:print:]]*)/(?<creator>[[:print:]&&[^/]]*?)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
      "@{creator}{modelId}" => %r{^/?.*?@(?<creator>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$},
      "{creator}/{collection}/{tags}/{modelName}{modelId}" => %r{^/?.*?(?<creator>[[:print:]&&[^/]]*?)/(?<collection>[[:print:]&&[^/]]*?)/(?<tags>[[:print:]]*)/(?<model_name>[[:print:]&&[^/]]*?)(?<model_id>#[[:digit:]]+)?$}
    }.each_pair do |tag, regexp|
      it "correctly converts #{tag} into a regexp matcher" do
        allow(SiteSettings).to receive(:model_path_template).and_return(tag)
        expect(described_class.send(:path_parse_pattern)).to eql regexp
      end
    end

    {
      "{tags}/{modelName}{modelId}" => {
        tags: ["top", "middle", "bottom"],
        model_name: "prefix - name"
      },
      "{creator}/{modelName}{modelId}" => {
        creator: "bottom",
        model_name: "prefix - name"
      },
      "{collection}/{modelName}{modelId}" => {
        collection: "bottom",
        model_name: "prefix - name"
      },
      "{tags}/{creator}/{modelName}{modelId}" => {
        creator: "bottom",
        tags: ["top", "middle"],
        model_name: "prefix - name"
      },
      "{creator}{modelId}" => {
        creator: "prefix - name"
      },
      "{tags}/{creator}/{collection} - {modelName}{modelId}" => {
        tags: ["top", "middle"],
        creator: "bottom",
        collection: "prefix",
        model_name: "name"
      }
    }.each_pair do |tag, values|
      it "correctly matches components of #{tag}" do
        allow(SiteSettings).to receive(:model_path_template).and_return(tag)
        expect(described_class.send(:extract_path_components, model)).to eql values
      end
    end
  end
end
