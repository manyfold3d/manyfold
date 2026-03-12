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
end
