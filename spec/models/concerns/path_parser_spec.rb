require "rails_helper"

RSpec.describe PathParser do


  context "tag generation" do
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

      it "generates tag from _ delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from + delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["this", "is", "fantasy", "model"]
      end

      it "generates tag from - delimited file names" do
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

      it "generates tags from _ delimited file names" do
        model = build(:model, path: "/library1/stuff/this-is-a-fantasy-model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from + delimited file names" do
        model = build(:model, path: "/library1/stuff/this+is+a+fantasy+model")
        model.autogenerate_tags_from_path!
        expect(model.tag_list).to eq ["fantasy", "model"]
      end

      it "generates tags from - delimited file names" do
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

end
