require "rails_helper"

RSpec.describe ChangeDetection do
  context "with hidden files and folders" do
    around do |ex|
      MockDirectory.create([
        "model/file.stl",
        "model/.hidden.stl",
        "model/.git/file.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "does not include hidden files in file list" do
      expect(library.indexable_files).not_to include "model/.hidden.stl"
    end

    it "does not include hidden folder contents in file list" do
      expect(library.indexable_files).not_to include "model/.git/file.stl"
    end
  end

  context "with folders that look like filenames" do
    around do |ex|
      MockDirectory.create([
        "wrong.stl/file.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "does not include directories in file list" do
      expect(library.indexable_files).not_to include "wrong.stl"
    end

    it "does include files within directories in file list" do
      expect(library.indexable_files).to include "wrong.stl/file.stl"
    end
  end

  context "with a case sensitive filesystem", :case_sensitive do
    around do |ex|
      MockDirectory.create([
        "model/file.obj",
        "model/file.OBJ",
        "model/file.Obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "detects lowercase file extensions" do
      expect(library.indexable_files).to include "model/file.obj"
    end

    it "detects uppercase file extensions" do
      expect(library.indexable_files).to include "model/file.OBJ"
    end

    it "detects mixed case file extensions" do
      expect(library.indexable_files).to include "model/file.Obj"
    end
  end

  context "with unusual characters in model folder names" do
    around do |ex|
      MockDirectory.create([
        "model [test]/file.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "detects files inside models with square brackets" do
      expect(library.indexable_files).to include "model [test]/file.obj"
    end
  end

  context "with existing models and files" do
    around do |ex|
      MockDirectory.create([
        "model/indexed.obj",
        "model/datapackage.json",
        "new/new.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let!(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    before do
      model = create(:model, library: library, path: "model")
      create(:model_file, model: model, filename: "indexed.obj")
      create(:model_file, model: model, filename: "datapackage.json")
      gone = create(:model, library: library, path: "gone")
      create(:model_file, model: gone, filename: "missing.obj")
    end

    it "lists indexed files" do
      expect(library.indexed_files).to include "model/indexed.obj"
    end

    it "ignores datapackages when listing indexed files" do
      expect(library.indexed_files).not_to include "model/datapackage.json"
    end

    it "ignores datapackages when listing indexable files" do
      expect(library.indexable_files).not_to include "model/datapackage.json"
    end

    it "includes new files when listing indexable files" do
      expect(library.indexable_files).to include "new/new.obj"
    end

    it "includes known files when listing indexable files" do
      expect(library.indexable_files).to include "model/indexed.obj"
    end

    it "includes missing files when listing indexed files" do
      expect(library.indexable_files).to include "gone/missing.obj"
    end
  end

  context "with existing non-indexable files" do
    around do |ex|
      MockDirectory.create([
        "model/test.pptx",
        "model/test.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    before do
      m = create(:model, path: "model", library: library)
      create(:model_file, model: m, filename: "test.pptx")
      create(:model_file, model: m, filename: "test.stl")
    end

    it "does not include folder contents in file list" do
      expect(library.folders_with_changes).not_to include "model"
    end
  end

  context "with a thingiverse-style folder with error files" do
    around do |ex|
      MockDirectory.create([
        "thingiverse_model/files/part_one.stl",
        "thingiverse_model/images/preview.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let(:model) { create(:model, library: library, path: "thingiverse_model") }

    it "detects changes of correct files" do
      expect(library.folders_with_changes).to contain_exactly("thingiverse_model")
    end

    it "doesn't detect changes because of incorrect file in images folder" do
      create(:model_file, model: model, filename: "files/part_one.stl") # We already know about the correct file
      expect(library.folders_with_changes).to be_empty
    end
  end

  context "with nested models" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/nested/part_2.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    before do
      model = create(:model, library: library, path: "model_one")
      create(:model_file, model: model, filename: "part_1.obj")
      create(:model_file, model: model, filename: "nested/part_2.obj")
    end

    it "does not pick up already-merged subfolder" do
      expect(library.folders_with_changes).to be_empty
    end
  end

  context "when randomly sampling folders" do
    around do |ex|
      MockDirectory.create([
        "first/second/leaf/model.stl",
        "third/fourth/leaf/model.stl",
        "fifth/leaf/model.stl",
        "sixth/leaf/model.stl",
        "first/second/nonindexable/nope.nope",
        "first/.hidden/model.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "returns as many folders as exist up to the requested amount" do
      expect(library.sample(10).length).to eq 4
    end

    it "only returns the requested number of entries" do
      expect(library.sample(2).length).to eq 2
    end

    it "returns a leaf folder" do
      expect(library.sample(10)).to include "first/second/leaf"
    end

    it "doesn't include folders above leaves" do
      expect(library.sample(10)).not_to include "first/second"
    end

    it "doesn't include folders without indexable files" do
      expect(library.sample(10)).not_to include "first/second/nonindexable"
    end

    it "doesn't include hidden folders" do
      expect(library.sample(10)).not_to include "first/.hidden"
    end

    it "doesn't include root folder" do
      expect(library.sample(10)).not_to include("", ".", "./")
    end
  end
end
