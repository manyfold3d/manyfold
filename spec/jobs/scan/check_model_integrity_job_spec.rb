require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::CheckModelIntegrityJob do
  context "when checking for missing files" do
    around do |ex|
      MockDirectory.create([
        "model_one/test.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "flags models with no folder as a problem" do
      model = create(:model, library: library, path: "missing")
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("missing")
    end

    it "flags up problems for files that don't exist on disk" do
      model = create(:model, path: "model_one", library: library)
      file = create(:model_file, filename: "missing.stl", model: model)
      File.delete(File.join(library.path, file.path_within_library))
      described_class.perform_now(model.id)
      expect(model.model_files.first.problems.map(&:category)).to include("missing")
    end
  end

  context "when checking for missing image files" do
    it "flags models without images as a problem" do
      model = create(:model)
      create(:model_file, filename: "3d.stl", model: model)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_image")
    end
  end

  context "when checking for missing 3d files" do
    it "flags models without 3d files as a problem" do
      model = create(:model)
      create(:model_file, filename: "image.jpg", model: model)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_3d_model")
    end
  end

  context "when checking for missing license" do
    it "flags models without license as a problem" do
      model = create(:model, license: nil)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_license")
    end

    it "doesn't raise a problem for models with license" do
      model = create(:model, license: "CC-BY-4.0")
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).not_to include("no_license")
    end
  end

  context "when checking for missing creator" do
    it "flags models without creator as a problem" do
      model = create(:model)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_creator")
    end

    it "doesn't raise a problem for models with creator" do
      creator = create(:creator)
      model = create(:model, creator: creator)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).not_to include("no_creator")
    end
  end

  context "when checking for missing links" do
    it "flags models without link as a problem" do
      model = create(:model)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_links")
    end

    it "doesn't raise a problem for models with a link" do
      link = Link.new url: "https://example.com"
      model = create(:model, links: [link])
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).not_to include("no_links")
    end
  end

  context "when checking for missing tags" do
    it "flags models without tags as a problem" do
      model = create(:model)
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).to include("no_tags")
    end

    it "doesn't raise a problem for models with tags" do
      model = create(:model, tag_list: "tag")
      described_class.perform_now(model.id)
      expect(model.problems.map(&:category)).not_to include("no_tags")
    end
  end

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
