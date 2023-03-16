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
        allow(SiteSettings).to receive(:model_tags_stop_words_locale).and_return("en")
        allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(true)
        allow(SiteSettings).to receive(:model_tags_custom_stop_words).and_return(["chicken"])
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
    let(:model) { build(:model, path: "/library1/stuff/tags/are/greedy/model-name") }

    before do
      allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
    end

    it "parses tags" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{tags}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.tag_list).to eq ["library1", "stuff", "tags", "are", "greedy"]
    end

    it "parses creator" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "greedy"
    end

    it "parses collection" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{collection}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.collection.name).to eq "greedy"
    end

    it "parses everything at once" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{collection}/{tags}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "library1"
      expect(model.collection.name).to eq "stuff"
      expect(model.tag_list).to eq ["tags", "are", "greedy"]
    end

    it "ignores extra path components" do
      allow(SiteSettings).to receive(:model_path_template).and_return("{creator}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.creator.name).to eq "greedy"
      expect(model.collection).to be_nil
      expect(model.tag_list).to eq []
    end

    it "handles a completely empty template" do
      allow(SiteSettings).to receive(:model_path_template).and_return("")
      model.parse_metadata_from_path!
      expect(model.creator).to be_nil
      expect(model.collection).to be_nil
      expect(model.tag_list).to eq []
    end

    it "removes stop words from tag lists" do
      allow(SiteSettings).to receive(:model_tags_stop_words_locale).and_return("en")
      allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(true)
      allow(SiteSettings).to receive(:model_tags_custom_stop_words).and_return(["stuff"])
      allow(SiteSettings).to receive(:model_path_template).and_return("{tags}/{modelName}{modelId}")
      model.parse_metadata_from_path!
      expect(model.tag_list).to eq ["library1", "tags", "greedy"]
    end
  end
end
