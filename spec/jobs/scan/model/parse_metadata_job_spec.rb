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
        expect(model.tag_list).not_to include("a")
      end

      it "generates tag from whitespace delimited file names" do
        model = create(:model, path: "/library1/stuff/this is a fantasy model", tags: [])
        described_class.perform_now(model.id)
        model.reload
        expect(model.tag_list).to include("this", "is", "fantasy", "model")
      end

      it "generates tag from underscore delimited file names" do
        model = create(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        described_class.perform_now(model.id)
        model.reload
        expect(model.tag_list).to include("this", "is", "fantasy", "model")
      end

      it "generates tag from plus delimited file names" do
        model = create(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        described_class.perform_now(model.id)
        model.reload
        expect(model.tag_list).to include("this", "is", "fantasy", "model")
      end

      it "generates tag from hyphen delimited file names" do
        model = create(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        described_class.perform_now(model.id)
        model.reload
        expect(model.tag_list).to include("this", "is", "fantasy", "model")
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

      it "filters custom stop words" do
        model = create(:model, path: "/library1/stuff/this-is-a-scifi-chicken-model")
        described_class.perform_now(model.id)
        expect(model.reload.tag_list).not_to include("chicken")
      end
    end
  end

  context "when parsing with a path template" do
    let(:model) { create(:model, path: "/library-1/stuff/tags/are/greedy/model-name") }

    before do
      allow(SiteSettings).to receive_messages(
        model_tags_tag_model_directory_name: false,
        parse_metadata_from_path: true,
        model_tags_auto_tag_new: nil,
        model_tags_filter_stop_words: false
      )
    end

    it "parses tags" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{tags}/{modelName}{modelId}")
      described_class.perform_now(model.id)
      model.reload
      expect(model.tag_list).to include("library 1", "stuff", "tags", "are", "greedy")
    end

    it "parses creator" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator.name).to eq "Greedy"
    end

    it "parses collection" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{collection}/{modelName}{modelId}")
      described_class.perform_now(model.id)
      model.reload
      expect(model.collection.name).to eq "Greedy"
    end

    it "parses everything at once" do # rubocop:todo RSpec/MultipleExpectations, RSpec/ExampleLength
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{collection}/{tags}/{modelName}{modelId}")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator.name).to eq "Library 1"
      expect(model.collection.name).to eq "Stuff"
      expect(model.tag_list).to eq ["tags", "are", "greedy"]
    end

    it "ignores extra path components" do # rubocop:todo RSpec/MultipleExpectations, RSpec/ExampleLength
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator.name).to eq "Greedy"
      expect(model.collection).to be_nil
      expect(model.tag_list).to eq []
    end

    it "handles a completely empty template" do # rubocop:todo RSpec/MultipleExpectations, RSpec/ExampleLength
      allow(SiteSettings).to receive(:model_path_template).and_return("")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator).to be_nil
      expect(model.collection).to be_nil
      expect(model.tag_list).to eq []
    end

    it "removes stop words from tag lists" do # rubocop:todo RSpec/ExampleLength
      allow(SiteSettings).to receive_messages(
        model_tags_stop_words_locale: "en",
        model_tags_filter_stop_words: true,
        model_tags_custom_stop_words: ["stuff"],
        model_path_template: "{tags}/{modelName}{modelId}"
      )
      described_class.perform_now(model.id)
      expect(model.tag_list).not_to include "stuff"
    end
  end

  context "when parsing creator out of a path" do
    before do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}")
    end

    it "creates a new creator from a human name if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = create(:model, path: "Bruce Wayne/model-name")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator.name).to eq "Bruce Wayne"
      expect(model.creator.slug).to eq "bruce-wayne"
    end

    it "creates a new creator from a slug if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = create(:model, path: "bruce-wayne/model-name")
      described_class.perform_now(model.id)
      model.reload
      expect(model.creator.name).to eq "Bruce Wayne"
      expect(model.creator.slug).to eq "bruce-wayne"
    end

    context "with an existing creator" do
      let!(:creator) { create(:creator, name: "Bruce Wayne", slug: "bruce-wayne") }

      it "matches safe path components" do
        model = create(:model, path: "bruce-wayne/model-name")
        described_class.perform_now(model.id)
        model.reload
        expect(model.creator).to eq creator
      end

      it "matches unsafe path components" do
        model = create(:model, path: "Bruce Wayne/model-name")
        described_class.perform_now(model.id)
        model.reload
        expect(model.creator).to eq creator
      end
    end
  end

  context "when parsing collection out of a path" do
    before do
      allow(SiteSettings).to receive(:model_path_template).and_return("{collection}/{modelName}")
    end

    it "creates a new collection from a human name if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = create(:model, path: "Wonderful Toys/model-name")
      described_class.perform_now(model.id)
      model.reload
      expect(model.collection.name).to eq "Wonderful Toys"
      expect(model.collection.slug).to eq "wonderful-toys"
    end

    it "creates a new collection from a slug if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = create(:model, path: "wonderful-toys/model-name")
      described_class.perform_now(model.id)
      model.reload
      expect(model.collection.name).to eq "Wonderful Toys"
      expect(model.collection.slug).to eq "wonderful-toys"
    end

    context "with an existing collection" do
      let!(:collection) { create(:collection, name: "Wonderful Toys", slug: "wonderful-toys") }

      it "matches safe path components" do
        model = create(:model, path: "wonderful-toys/model-name")
        described_class.perform_now(model.id)
        model.reload
        expect(model.collection).to eq collection
      end

      it "matches unsafe path components" do
        model = create(:model, path: "Wonderful Toys/model-name")
        described_class.perform_now(model.id)
        model.reload
        expect(model.collection).to eq collection
      end
    end
  end

  it "discards model ID and doesn't include it in model name" do # rubocop:todo RSpec/MultipleExpectations
    allow(SiteSettings).to receive(:model_path_template).and_return("{modelName}{modelId}")
    model = create(:model, path: "model-name#1234")
    described_class.perform_now(model.id)
    model.reload
    expect(model.name).to eq "Model Name"
  end

  it "handles paths matching a complex templates" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    allow(SiteSettings).to receive_messages(
      parse_metadata_from_path: true,
      model_path_template: "{tags}/{creator} - {modelName}{modelId}",
      model_tags_auto_tag_new: nil
    )
    model = create(:model, path: "human/wizard/bruce-wayne - model-name#1234")
    described_class.perform_now(model.id)
    model.reload
    expect(model.name).to eq "Model Name"
    expect(model.creator.name).to eq "Bruce Wayne"
    expect(model.tag_list).to include("human", "wizard")
  end
end
