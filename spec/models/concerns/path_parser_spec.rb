require "rails_helper"

RSpec.describe PathParser do
  context "when generating tags" do
    context "without stop word filtering" do
      before do
        allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
      end

      it "skips single letter tags" do
        model = build(:model, path: "/library1/stuff/a")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq []
      end

      it "generates tag from whitespace delimited file names" do
        model = build(:model, path: "/library1/stuff/this is a fantasy model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from underscore delimited file names" do
        model = build(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from plus delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from hyphen delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.generate_tags_from_directory_name!
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

      it "generates tags from whitespace delimited file names" do
        model = build(:model, path: "/library1/stuff/this is a fantasy model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from underscore delimited file names" do
        model = build(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from plus delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from hyphen delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags and filters custom stop words" do
        model = build(:model, path: "/library1/stuff/this-is-a-scifi-chicken-model")
        model.generate_tags_from_directory_name!
        expect(model.tag_list).to eq ["scifi", "model"]
      end
    end
  end

  context "when given a path template" do
    let(:model) { build(:model, path: "/top/middle/bottom/prefix - name#42") }

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
        expect(model.send(:path_parse_pattern)).to eql regexp
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
        expect(model.send(:extract_path_components)).to eql values
      end
    end
  end

  context "when parsing with a path template" do
    let(:model) { build(:model, path: "/library-1/stuff/tags/are/greedy/model-name") }

    before do
      allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
    end

    it "parses tags" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{tags}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.tag_list).to eq ["library 1", "stuff", "tags", "are", "greedy"]
    end

    it "parses creator" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "Greedy"
    end

    it "parses collection" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{collection}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.collection.name).to eq "Greedy"
    end

    it "parses everything at once" do # rubocop:todo RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{collection}/{tags}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "Library 1"
      expect(model.collection.name).to eq "Stuff"
      expect(model.tag_list).to eq ["tags", "are", "greedy"]
    end

    it "ignores extra path components" do # rubocop:todo RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "Greedy"
      expect(model.collection).to be_nil
      expect(model.tag_list).to eq []
    end

    it "handles a completely empty template" do # rubocop:todo RSpec/MultipleExpectations
      allow(SiteSettings).to receive(:model_path_template).and_return("")
      model.parse_metadata_from_path!
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
      model.parse_metadata_from_path!
      expect(model.tag_list).to eq ["library 1", "tags", "greedy"]
    end
  end

  context "when parsing creator out of a path" do
    before do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}")
    end

    it "creates a new creator from a human name if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = build(:model, path: "Bruce Wayne/model-name")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "Bruce Wayne"
      expect(model.creator.slug).to eq "bruce-wayne"
    end

    it "creates a new creator from a slug if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = build(:model, path: "bruce-wayne/model-name")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "Bruce Wayne"
      expect(model.creator.slug).to eq "bruce-wayne"
    end

    context "with an existing creator" do
      let!(:creator) { create(:creator, name: "Bruce Wayne", slug: "bruce-wayne") }

      it "matches safe path components" do
        model = build(:model, path: "bruce-wayne/model-name")
        model.parse_metadata_from_path!
        expect(model.creator).to eq creator
      end

      it "matches unsafe path components" do
        model = build(:model, path: "Bruce Wayne/model-name")
        model.parse_metadata_from_path!
        expect(model.creator).to eq creator
      end
    end
  end

  context "when parsing collection out of a path" do
    before do
      allow(SiteSettings).to receive(:model_path_template).and_return("{collection}/{modelName}")
    end

    it "creates a new collection from a human name if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = build(:model, path: "Wonderful Toys/model-name")
      model.parse_metadata_from_path!
      expect(model.collection.name).to eq "Wonderful Toys"
      expect(model.collection.slug).to eq "wonderful-toys"
    end

    it "creates a new collection from a slug if there's no match" do # rubocop:todo RSpec/MultipleExpectations
      model = build(:model, path: "wonderful-toys/model-name")
      model.parse_metadata_from_path!
      expect(model.collection.name).to eq "Wonderful Toys"
      expect(model.collection.slug).to eq "wonderful-toys"
    end

    context "with an existing collection" do
      let!(:collection) { create(:collection, name: "Wonderful Toys", slug: "wonderful-toys") }

      it "matches safe path components" do
        model = build(:model, path: "wonderful-toys/model-name")
        model.parse_metadata_from_path!
        expect(model.collection).to eq collection
      end

      it "matches unsafe path components" do
        model = build(:model, path: "Wonderful Toys/model-name")
        model.parse_metadata_from_path!
        expect(model.collection).to eq collection
      end
    end
  end

  it "discards model ID and doesn't include it in model name" do # rubocop:todo RSpec/MultipleExpectations
    allow(SiteSettings).to receive(:model_path_template).and_return("{modelName}{modelId}")
    model = build(:model, path: "model-name#1234")
    model.parse_metadata_from_path!
    expect(model.name).to eq "Model Name"
    expect(model.slug).to eq "model-name"
  end

  it "handles paths matching a complex templates" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    allow(SiteSettings).to receive(:model_path_template).and_return("{tags}/{creator} - {modelName}{modelId}")
    model = build(:model, path: "human/wizard/bruce-wayne - model-name#1234")
    model.parse_metadata_from_path!
    expect(model.name).to eq "Model Name"
    expect(model.creator.name).to eq "Bruce Wayne"
    expect(model.tag_list).to eq ["human", "wizard"]
  end
end
