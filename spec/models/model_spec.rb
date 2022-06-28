require "rails_helper"

RSpec.describe Model, type: :model do
  it "is not valid without a path" do
    expect(build(:model, path: nil)).not_to be_valid
  end

  it "is not valid without a name" do
    expect(build(:model, name: nil)).not_to be_valid
  end

  it "is not valid without being part of a library" do
    expect(build(:model, library: nil)).not_to be_valid
  end

  it "is valid if it has a path, name and library" do
    expect(build(:model)).to be_valid
  end

  it "has many files" do
    expect(build(:model).model_files).to eq []
  end

  context "tag generation" do
    context "without stop word filtering" do
      before :each do
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
      before :each do
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

  context "with a library on disk" do
    before :each do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/library1").and_return(true)
      allow(File).to receive(:exist?).with("/library2").and_return(true)
    end

    it "must have a unique path within its library" do
      library = create(:library, path: "/library1")
      create(:model, library: library, path: "model")
      expect(build(:model, library: library, path: "model")).not_to be_valid
    end

    it "can have the same path as a model in a different library" do
      library1 = create(:library, path: "/library1")
      create(:model, library: library1, path: "model")
      library2 = create(:library, path: "/library2")
      expect(build(:model, library: library2, path: "model")).to be_valid
    end
  end

  context "nested inside another" do
    before :each do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/library").and_return(true)
    end

    let(:library) { create(:library, path: "/library") }

    it "identifies the parent" do
      parent = create(:model, library: library, path: "model")
      child = create(:model, library: library, path: "model/nested")
      expect(child.parents).to eql [parent]
    end

    context "merging into parent" do
      before :each do
        @parent = create(:model, library: library, path: "model")
        @child = create(:model, library: library, path: "model/nested")
      end

      it "moves files" do
        file = create(:model_file, model: @child, filename: "part.stl")
        @child.merge_into_parent!
        file.reload
        expect(file.filename).to eql "nested/part.stl"
        expect(file.model).to eql @parent
      end

      it "deletes merged model" do
        expect {
          @child.merge_into_parent!
        }.to change { Model.count }.from(2).to(1)
      end
    end
  end
end
