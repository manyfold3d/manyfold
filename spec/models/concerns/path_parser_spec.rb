require "rails_helper"

RSpec.describe PathParser do
  context "when generating tags" do
    context "without stop word filtering" do
      before do
        allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
      end

      it "skips single letter tags" do
        model = build(:model, path: "/library1/stuff/a")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq []
      end

      it "generates tag from whitespace delimited file names" do
        model = build(:model, path: "/library1/stuff/this is a fantasy model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from underscore delimited file names" do
        model = build(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from plus delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from hyphen delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.autogenerate_tags_from_path!
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
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from underscore delimited file names" do
        model = build(:model, path: "/library1/stuff/this_is_a_fantasy_model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from plus delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from hyphen delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags and filters custom stop words" do
        model = build(:model, path: "/library1/stuff/this-is-a-scifi-chicken-model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["scifi", "model"]
      end
    end
  end

  context "when parsing with a prefix template" do
    let(:model) { build(:model, path: "/library1/stuff/tags/are/greedy/model-name") }

    before do
      allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(false)
    end

    it "parses tags" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{tags}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.tag_list).to eq ["library1", "stuff", "tags", "are", "greedy"]
    end

    it "parses creator" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{creator}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.creator.name).to eq "library1"
    end

    it "parses collection" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{collection}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.collection_list).to eq ["library1"]
    end

    it "parses everything at once" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{creator}/{collection}/{tags}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.creator.name).to eq "library1"
      expect(model.collection_list).to eq ["stuff"]
      expect(model.tag_list).to eq ["tags", "are", "greedy"]
    end

    it "ignores extra path components" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{creator}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.creator.name).to eq "library1"
      expect(model.collection_list).to eq []
      expect(model.tag_list).to eq []
    end

    it "handles a completely empty template" do
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("")
      model.autogenerate_creator_from_prefix_template!
      expect(model.creator).to be_nil
      expect(model.collection_list).to eq []
      expect(model.tag_list).to eq []
    end

    it "removes stop words from tag lists" do
      allow(SiteSettings).to receive(:model_tags_stop_words_locale).and_return("en")
      allow(SiteSettings).to receive(:model_tags_filter_stop_words).and_return(true)
      allow(SiteSettings).to receive(:model_tags_custom_stop_words).and_return(["stuff"])
      allow(SiteSettings).to receive(:model_path_prefix_template).and_return("{tags}")
      model.autogenerate_creator_from_prefix_template!
      expect(model.tag_list).to eq ["library1", "tags", "greedy"]
    end
  end
end
