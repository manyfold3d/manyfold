require "rails_helper"
require "support/mock_directory"

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

  context "with license information" do
    it "allows nil license" do
      m = build(:model, license: nil)
      expect(m).to be_valid
    end

    it "stores license info in SPDX" do
      m = build(:model, license: "MIT")
      expect(m).to be_valid
    end

    it "supports complex SPDX definitions" do
      m = build(:model, license: "MIT OR AGPL-3.0+")
      expect(m).to be_valid
    end

    it "checks for SPDX validity" do
      m = build(:model, license: "Made up license")
      expect(m).not_to be_valid
      expect(m.errors[:license].first).to eq "is not a valid license"
    end

    it "allows LicenseRef-Commercial to represent private use only" do
      # See https://scancode-licensedb.aboutcode.org/commercial-license.html
      m = build(:model, license: "LicenseRef-Commercial")
      expect(m).to be_valid
    end

    it "can remove a license on save" do
      m = create(:model, license: "MIT")
      m.license = nil
      expect(m).to be_valid
    end

    it "normalizes blank licenses to nil" do
      m = build(:model, license: "")
      m.validate
      expect(m.license).to be_nil
    end
  end

  it "strips leading and trailing separators from paths" do
    model = create(:model, path: "/models/car/")
    expect(model.path).to eq "models/car"
  end

  it "automatically generates a slug from the name" do
    model = create(:model, name: "Spın̈al Tap")
    expect(model.slug).to eq "spin-al-tap"
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

  context "when nested inside another" do
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

    context "when merging into parent" do
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

  context "when nested inside another with underscores in the name" do
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

  context "when organising" do
    around do |ex|
      Dir.mktmpdir do |library_path|
        @library_path = library_path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable
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

  context "when changing library" do
    around do |ex|
      Dir.mktmpdir do |library_path|
        Dir.mkdir File.join(library_path, "original_library")
        Dir.mkdir File.join(library_path, "new_library")
        @library_path = library_path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:original_library) { create(:library, path: File.join(@library_path, "original_library")) }
    let(:new_library) { create(:library, path: File.join(@library_path, "new_library")) }
    # rubocop:enable RSpec/InstanceVariable
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

  context "with filesystem conflicts" do
    around do |ex|
      MockDirectory.create([
        "model/file.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    let(:model_without_leading_separator) {
      create(:model, library: library, path: "model")
    }
    let(:model_with_leading_separator) {
      model = create(:model, library: library, path: "model")
      # rubocop:disable Rails/SkipsModelValidations
      model.update_columns(path: "/model") # Set leading separator bypassing validators
      # rubocop:enable Rails/SkipsModelValidations
      model
    }

    it "allows removal of leading separators without having to move files" do
      expect(model_with_leading_separator.path).to eql "/model"
      expect { model_with_leading_separator.update!(path: "model") }.not_to raise_error
    end

    it "fails validation if removing a leading separator causes a conflict" do
      expect(model_with_leading_separator.path).to eql "/model"
      expect(model_without_leading_separator.path).to eql "model"
      expect { model_with_leading_separator.update!(path: "model") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "when removing files from disk" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.3mf"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable
    let(:model) { create(:model, library: library, path: "model_one") }

    it "removes original folder from disk" do
      expect { model.delete_from_disk_and_destroy }.to(
        change { File.exist?(model.absolute_path) }.from(true).to(false)
      )
    end

    it "ignores missing files on deletion" do
      model.update! path: "gone"
      expect { model.delete_from_disk_and_destroy }.not_to raise_exception
    end

    it "calls standard destroy" do
      allow(model).to receive(:destroy)
      model.delete_from_disk_and_destroy
      expect(model).to have_received(:destroy).once
    end

    it "calls delete_from_disk_and_destroy on files" do
      file = create(:model_file, model: model, filename: "part_1.3mf", digest: "1234")
      allow(file).to receive(:delete_from_disk_and_destroy)
      allow(model).to receive(:model_files).and_return([file])
      model.delete_from_disk_and_destroy
      expect(file).to have_received(:delete_from_disk_and_destroy).once
    end
  end
end
