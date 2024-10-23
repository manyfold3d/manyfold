require "rails_helper"
require "support/mock_directory"

RSpec.describe Model do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"

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

    it "checks for SPDX validity" do # rubocop:todo RSpec/MultipleExpectations
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

  context "with a library on disk" do
    around do |ex|
      MockDirectory.create([
        "original_library/model/part.stl",
        "new_library/model/part.stl"
      ]) do |path|
        @libraries_path = path
        ex.run
      end
    end

    it "must have a unique path within its library" do
      library = create(:library, path: "#{@libraries_path}/original_library") # rubocop:todo RSpec/InstanceVariable
      create(:model, library: library, path: "model")
      expect(build(:model, library: library, path: "model")).not_to be_valid
    end

    it "can have the same path as a model in a different library" do
      original_library = create(:library, path: "#{@libraries_path}/original_library") # rubocop:todo RSpec/InstanceVariable
      create(:model, library: original_library, path: "model")
      new_library = create(:library, path: "#{@libraries_path}/new_library") # rubocop:todo RSpec/InstanceVariable
      expect(build(:model, library: new_library, path: "model")).to be_valid
    end
  end

  context "when nested inside another" do
    around do |ex|
      MockDirectory.create([
        "parent/parent_part.stl",
        "parent/child/child_part.stl",
        "parent/child/duplicate.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:parent) { create(:model, library: library, path: "parent") }
    let!(:child) { create(:model, library: library, path: "parent/child") }

    it "lists contained models" do
      expect(parent.contained_models.to_a).to eql [child]
    end

    it "identifies the parent" do
      expect(child.parents).to eql [parent]
    end

    it "has a bool check for contained models" do # rubocop:todo RSpec/MultipleExpectations
      expect(parent.contains_other_models?).to be true
      expect(child.contains_other_models?).to be false
    end

    context "when merging into parent" do
      it "moves files" do # rubocop:todo RSpec/MultipleExpectations
        file = create(:model_file, model: child, filename: "child_part.stl")
        child.merge_into! parent
        file.reload
        expect(file.filename).to eql "child/child_part.stl"
        expect(file.model).to eql parent
      end

      it "deletes merged model" do
        expect {
          child.merge_into! parent
        }.to change(described_class, :count).from(2).to(1)
      end
    end

    context "when merging models that have duplicated files" do
      before do
        create(:model_file, model: parent, filename: "parent_part.stl")
        create(:model_file, model: parent, filename: "child/duplicate.stl")
        create(:model_file, model: child, filename: "duplicate.stl")
        create(:model_file, model: child, filename: "child_part.stl")
      end

      it "removes duplicated file" do
        expect {
          child.merge_into! parent
        }.to change(ModelFile, :count).by(-1)
      end

      it "rehomes distinct file" do
        child.merge_into! parent
        expect(parent.model_files.exists?(filename: "child/child_part.stl")).to be true
      end

      it "keeps all real files intact" do
        child.merge_into! parent
        parent.model_files.each do |file|
          expect(file.exists_on_storage?).to be true
        end
      end
    end
  end

  context "when nested inside another with underscores in the name" do
    around do |ex|
      MockDirectory.create([
        "model_one/part.stl",
        "model_one/nested_model/part.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:parent) { create(:model, library: library, path: "model_one") }
    let!(:child) { create(:model, library: library, path: "model_one/nested_model") }

    it "correctly flags up contained models" do # rubocop:todo RSpec/MultipleExpectations
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

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:model) {
      FileUtils.mkdir_p(File.join(library.path, "original"))
      m = create(:model, library: library, name: "test model", path: "original")
      create(:model_file, model: m)
      m
    }

    it "moves model folder" do # rubocop:todo RSpec/MultipleExpectations
      expect { model.organize! }.not_to raise_error
      expect(Dir.exist?(File.join(library.path, "original"))).to be false
      expect(Dir.exist?(File.join(library.path, "@untagged", "test-model#1"))).to be true
    end

    it "has a validation error if the destination path already exists, and does not move anything" do # rubocop:todo RSpec/MultipleExpectations
      FileUtils.mkdir_p(File.join(library.path, "@untagged/test-model#1"))
      expect { model.organize! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Path already exists")
      expect(Dir.exist?(File.join(library.path, "original"))).to be true
    end

    it "throws an error if the model has submodels, and does not move anything" do # rubocop:todo RSpec/MultipleExpectations
      create(:model, library: library, name: "sub model", path: "original/submodel")
      expect { model.organize! }.to raise_error(ActiveRecord::RecordInvalid)
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

    # rubocop:todo RSpec/InstanceVariable
    let(:original_library) { create(:library, path: File.join(@library_path, "original_library")) }
    let(:new_library) { create(:library, path: File.join(@library_path, "new_library")) }
    # rubocop:enable RSpec/InstanceVariable
    let!(:model) {
      FileUtils.mkdir_p(File.join(original_library.path, "model"))
      m = create(:model, library: original_library, name: "test model", path: "model")
      create(:model_file, model: m)
      m
    }
    let(:submodel) { create(:model, library: original_library, name: "sub model", path: "model/submodel") }

    it "moves model folder" do # rubocop:todo RSpec/MultipleExpectations
      expect { model.update! library: new_library }.not_to raise_error
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be false
      expect(Dir.exist?(File.join(new_library.path, "model"))).to be true
    end

    it "has a validation error if the destination path already exists, and does not move folder" do # rubocop:todo RSpec/MultipleExpectations
      FileUtils.mkdir_p(File.join(new_library.path, "model"))
      expect { model.update! library: new_library }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Path already exists")
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be true
    end

    it "has a validation error if the model has submodels, and does not move anything" do # rubocop:todo RSpec/MultipleExpectations
      create(:model, library: original_library, name: "sub model", path: "model/submodel")
      expect { model.update! library: new_library }.to raise_error(ActiveRecord::RecordInvalid)
      expect(model.errors.full_messages).to include("Library can't be changed, model contains other models")
      expect(Dir.exist?(File.join(original_library.path, "model"))).to be true
      expect(Dir.exist?(File.join(new_library.path, "model"))).to be false
    end
  end

  context "when splitting" do
    subject!(:model) {
      m = create(:model, creator: create(:creator), collection: create(:collection), license: "CC-BY-4.0", caption: "test", notes: "note")
      m.tag_list << "tag1"
      m.tag_list << "tag2"
      create(:model_file, model: m)
      create(:model_file, model: m)
      m
    }

    it "creates a new model" do
      expect { model.split! }.to change(described_class, :count).by(1)
    end

    it "prepends 'Copy of' to name" do
      new_model = model.split!
      expect(new_model.name).to eq "Copy of #{model.name}"
    end

    [:notes, :caption, :collection, :creator, :license, :tags].each do |field|
      it "copies old model #{field}" do
        new_model = model.split!
        expect(new_model.send(field)).to eq model.send(field)
      end
    end

    it "creates an empty model if no files are specified" do
      new_model = model.split!
      expect(new_model.model_files).to be_empty
    end

    it "does not add or remove files" do
      expect { model.split! }.not_to change(ModelFile, :count)
    end

    it "adds selected files to new model" do
      new_model = model.split! files: [model.model_files.first]
      expect(new_model.model_files.count).to eq 1
    end

    it "retains existing preview file for new model if selected for split" do # rubocop:todo RSpec/MultipleExpectations
      file_to_split = model.model_files.first
      model.update!(preview_file: file_to_split)
      new_model = model.split! files: [file_to_split]
      expect(new_model.preview_file).to eq file_to_split
      expect(model.reload.preview_file).to be_nil
    end

    it "new model gets no preview file if not selected" do # rubocop:todo RSpec/MultipleExpectations
      preview_file = model.model_files.first
      model.update!(preview_file: preview_file)
      new_model = model.split! files: [model.model_files.last]
      expect(new_model.reload.preview_file).to be_nil
      expect(model.preview_file).to eq preview_file
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

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    let(:model_without_leading_separator) {
      create(:model, library: library, path: "model")
    }
    let(:model_with_leading_separator) {
      model = create(:model, library: library, path: "model")
      # Set leading separator bypassing validators
      model.update_columns(path: "/model") # rubocop:disable Rails/SkipsModelValidations
      model
    }

    it "allows removal of leading separators without having to move files" do # rubocop:todo RSpec/MultipleExpectations
      expect(model_with_leading_separator.path).to eql "/model"
      expect { model_with_leading_separator.update!(path: "model") }.not_to raise_error
    end

    it "fails validation if removing a leading separator causes a conflict" do # rubocop:todo RSpec/MultipleExpectations
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

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable
    let(:model) { create(:model, library: library, path: "model_one") }

    it "removes original folder from disk" do
      expect { model.delete_from_disk_and_destroy }.to(
        change { File.exist?(File.join(library.path, model.path)) }.from(true).to(false)
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

    it "calls delete_from_disk_and_destroy on files" do # rubocop:todo RSpec/ExampleLength
      file = create(:model_file, model: model, filename: "part_1.3mf", digest: "1234")
      allow(file).to receive(:delete_from_disk_and_destroy)
      mock = [file]
      without_partial_double_verification do
        allow(mock).to receive(:update_all).and_return(true)
      end
      allow(model).to receive(:model_files).and_return(mock)
      model.delete_from_disk_and_destroy
      expect(file).to have_received(:delete_from_disk_and_destroy).once
    end
  end

  context "when making changes" do
    it "queues creator-specific model creation job when model is created if a creator is set" do
      model = create(:model, creator: create(:creator))
      expect(Activity::CreatorAddedModelJob).to have_been_enqueued.with(model.id).at_least(:once)
    end

    it "queues creator-specific model creation job when model is updated if a creator has changed" do
      model = create(:model)
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      model.update(creator: create(:creator))
      expect(Activity::CreatorAddedModelJob).to have_been_enqueued.with(model.id).at_least(:once)
    end
  end

  it "detects if a model has both supported and unsupported files" do
    model = create(:model)
    create(:model_file, model: model, presupported: true)
    create(:model_file, model: model, presupported: false)
    expect(model.has_supported_and_unsupported?).to be true
  end

  it "detects if a model has only supported files" do
    model = create(:model)
    create(:model_file, model: model, presupported: true)
    expect(model.has_supported_and_unsupported?).to be false
  end

  it "detects if a model has only unsupported files" do
    model = create(:model)
    create(:model_file, model: model, presupported: false)
    expect(model.has_supported_and_unsupported?).to be false
  end

  it "generates list of file extensions" do
    model = create(:model)
    create(:model_file, model: model, filename: "test.stl")
    create(:model_file, model: model, filename: "test2.stl")
    create(:model_file, model: model, filename: "test.obj")
    expect(model.file_extensions.sort).to eq ["obj", "stl"]
  end
end
