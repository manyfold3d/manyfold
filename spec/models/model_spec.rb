require "rails_helper"

RSpec.describe Model do
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

  it "strips leading and trailing separators from paths" do
    model = create(:model, path: "/models/car/")
    expect(model.path).to eq "models/car"
  end

  context "with a library on disk" do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/original_library").and_return(true)
      allow(File).to receive(:exist?).with("/new_library").and_return(true)
    end

    it "must have a unique path within its library" do
      library = create(:library, path: "/original_library")
      create(:model, library: library, path: "model")
      expect(build(:model, library: library, path: "model")).not_to be_valid
    end

    it "can have the same path as a model in a different library" do
      original_library = create(:library, path: "/original_library")
      create(:model, library: original_library, path: "model")
      new_library = create(:library, path: "/new_library")
      expect(build(:model, library: new_library, path: "model")).to be_valid
    end
  end

  context "nested inside another" do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/library").and_return(true)
    end

    let(:library) { create(:library, path: "/library") }
    let!(:parent) { create(:model, library: library, path: "parent") }
    let!(:child) { create(:model, library: library, path: "parent/child") }

    it "lists contained models" do
      expect(parent.contained_models.to_a).to eql [child]
    end

    it "identifies the parent" do
      expect(child.parents).to eql [parent]
    end

    it "has a bool check for contained models" do
      expect(parent.contains_other_models?).to be true
      expect(child.contains_other_models?).to be false
    end

    context "merging into parent" do
      it "moves files" do
        file = create(:model_file, model: child, filename: "part.stl")
        child.merge_into! parent
        file.reload
        expect(file.filename).to eql "child/part.stl"
        expect(file.model).to eql parent
      end

      it "deletes merged model" do
        expect {
          child.merge_into! parent
        }.to change(described_class, :count).from(2).to(1)
      end
    end
  end

  context "nested inside another with underscores in the name" do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/library").and_return(true)
    end

    let(:library) { create(:library, path: "/library") }
    let!(:parent) { create(:model, library: library, path: "model_one") }
    let!(:child) { create(:model, library: library, path: "model_one/nested_model") }

    it "correctly flags up contained models" do
      expect(parent.contains_other_models?).to be true
      expect(child.contains_other_models?).to be false
    end
  end

  context "being organised" do
    around do |ex|
      Dir.mktmpdir do |library_path|
        @library_path = library_path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) }
    let!(:model) {
      FileUtils.mkdir_p(File.join(library.path, "original"))
      create(:model, library: library, name: "test model", path: "original")
    }

    it "moves model folder" do
      expect { model.update! organize: true }.not_to raise_error
      expect(Dir.exist?(File.join(library.path, "original"))).to be false
      expect(Dir.exist?(File.join(library.path, "@untagged", "test-model#1"))).to be true
    end

    it "has a validation error if the destination path already exists, and does not move anything" do
      FileUtils.mkdir_p(File.join(library.path, "@untagged/test-model#1"))
      expect { model.update! organize: true }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Path already exists")
      expect(Dir.exist?(File.join(library.path, "original"))).to be true
    end

    it "has a validation error if the model has submodels, and does not move anything" do
      create(:model, library: library, name: "sub model", path: "original/submodel")
      expect { model.update! organize: true }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Path can't be changed, model contains other models")
      expect(Dir.exist?(File.join(library.path, "original"))).to be true
      expect(Dir.exist?(File.join(library.path, "@untagged", "test-model#1"))).to be false
    end
  end

  context "changing library" do
    around do |ex|
      Dir.mktmpdir do |library_path|
        Dir.mkdir File.join(library_path, "original_library")
        Dir.mkdir File.join(library_path, "new_library")
        @library_path = library_path
        ex.run
      end
    end

    let(:original_library) { create(:library, path: File.join(@library_path, "original_library")) }
    let(:new_library) { create(:library, path: File.join(@library_path, "new_library")) }
    let!(:model) {
      FileUtils.mkdir_p(File.join(original_library.path, "model"))
      create(:model, library: original_library, name: "test model", path: "model")
    }
    let(:submodel) { create(:model, library: original_library, name: "sub model", path: "model/submodel") }

    it "moves model folder" do
      expect { model.update! library: new_library }.not_to raise_error
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be false
      expect(Dir.exist?(File.join(new_library.path, "model"))).to be true
    end

    it "has a validation error if the destination path already exists, and does not move folder" do
      FileUtils.mkdir_p(File.join(new_library.path, "model"))
      expect { model.update! library: new_library }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Path already exists")
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be true
    end

    it "has a validation error if the model has submodels, and does not move anything" do
      create(:model, library: original_library, name: "sub model", path: "model/submodel")
      expect { model.update! library: new_library }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Library can't be changed, model contains other models")
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be true
      expect(Dir.exist?(File.join(new_library.path, "model"))).to be false
    end
  end
end
