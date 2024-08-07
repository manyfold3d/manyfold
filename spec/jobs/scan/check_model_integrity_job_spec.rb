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

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
