require "rails_helper"
require "support/mock_directory"

RSpec.describe Model do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"
  it_behaves_like "Indexable"
  it_behaves_like "IndexableWithCreatorDelegation"
  it_behaves_like "Linkable"

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
    expect(build(:model).model_files).to be_empty
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

  it "strips leading and trailing backslashes from tags" do
    model = create(:model, tag_list: ["\\tag1", "tag2\\"])
    expect(model.tag_list).to contain_exactly("tag1", "tag2")
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

  context "with models in different libraries" do
    let(:library_a) { create(:library) }
    let(:library_b) { create(:library) }

    it "does not find a common root for models" do
      m1 = create(:model, path: "shared/common/folder", library: library_a)
      m2 = create(:model, path: "shared/parent/folder", library: library_b)
      expect(described_class.common_root(m1, m2)).to be_nil
    end
  end

  context "with a common root" do
    around do |ex|
      MockDirectory.create([
        "common/root/model_one/part_one.stl",
        "common/root/model_two/part_two.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:model_one) { create(:model, library: library, path: "common/root/model_one") }
    let!(:model_two) { create(:model, library: library, path: "common/root/model_two") }
    let!(:part_one) { create(:model_file, model: model_one, filename: "part_one.stl") } # rubocop:disable RSpec/LetSetup
    let!(:part_two) { create(:model_file, model: model_two, filename: "part_two.stl") } # rubocop:disable RSpec/LetSetup

    it "finds common root folder for a set of models" do
      expect(described_class.common_root(model_one, model_two)).to eq "common/root"
    end

    context "when merging into a new parent model" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let!(:new_model) { create(:model, library: library, path: "common/root") }

      before do
        new_model.merge! model_one, model_two
      end

      it "moves files" do
        expect(new_model.model_files.count).to eq 2
      end

      it "preserves subfolder paths within model" do # rubocop:disable RSpec/MultipleExpectations
        expect(new_model.model_files.exists?(filename: "model_one/part_one.stl")).to be true
        expect(new_model.model_files.exists?(filename: "model_two/part_two.stl")).to be true
      end

      it "handles filename clashes"

      it "removes old models" do # rubocop:disable RSpec/MultipleExpectations
        expect { model_one.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { model_two.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "with disjoint models" do
    around do |ex|
      MockDirectory.create([
        "no/common/root/model_one/part_one.stl",
        "common/root/model_two/part_two.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:model_one) { create(:model, library: library, path: "no/common/root/model_one") }
    let!(:model_two) { create(:model, library: library, path: "common/root/model_two") }
    let!(:part_one) { create(:model_file, model: model_one, filename: "part_one.stl") } # rubocop:disable RSpec/LetSetup
    let!(:part_two) { create(:model_file, model: model_two, filename: "part_two.stl") } # rubocop:disable RSpec/LetSetup

    it "detects if there is no common root for a set of models" do
      expect(described_class.common_root(model_one, model_two)).to be_nil
    end

    it "detects disjoint models" do
      expect(model_one.disjoint?(model_two)).to be true
    end

    context "when merging into an existing model" do
      before do
        model_one.merge! model_two
      end

      it "moves files" do
        expect(model_one.model_files.count).to eq 2
      end

      it "does not change paths within model" do
        expect(model_one.model_files.exists?(filename: "part_two.stl")).to be true
      end

      it "handles filename clashes"

      it "removes old model" do
        expect { model_two.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
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

    it "parent contains child" do
      expect(parent.contains?(child)).to be true
    end

    it "child does not contain parent" do
      expect(child.contains?(parent)).to be false
    end

    it "parent and child are not disjoint" do # rubocop:todo RSpec/MultipleExpectations
      expect(parent.disjoint?(child)).to be false
      expect(child.disjoint?(parent)).to be false
    end

    it "has a bool check for contained models" do # rubocop:todo RSpec/MultipleExpectations
      expect(parent.contains_other_models?).to be true
      expect(child.contains_other_models?).to be false
    end

    it "detects parent as common root with child" do
      expect(described_class.common_root(parent, child)).to eq "parent"
    end

    it "can merge all contained models at once" do
      expect { parent.merge!(parent.contained_models) }.to change(described_class, :count).by(-1)
    end

    context "when merging a child model into a parent" do
      it "moves files" do # rubocop:todo RSpec/MultipleExpectations
        file = create(:model_file, model: child, filename: "child_part.stl")
        parent.merge! child
        file.reload
        expect(file.filename).to eql "child/child_part.stl"
        expect(file.model).to eql parent
      end

      it "deletes merged model" do
        expect {
          parent.merge! child
        }.to change(described_class, :count).from(2).to(1)
      end
    end

    context "when merging models that have duplicated files" do
      before do
        create(:model_file, model: parent, filename: "parent_part.stl")
        create(:model_file, model: parent, filename: "child/duplicate.stl", digest: "abcd")
        create(:model_file, model: child, filename: "duplicate.stl", digest: "abcd")
        create(:model_file, model: child, filename: "child_part.stl")
      end

      it "removes duplicated file" do
        expect {
          parent.merge! child
        }.to change(ModelFile, :count).by(-1)
      end

      it "rehomes distinct file" do
        parent.merge! child
        expect(parent.model_files.exists?(filename: "child/child_part.stl")).to be true
      end

      it "keeps all real files intact" do
        parent.merge! child
        parent.model_files.each do |file|
          expect(file.exists_on_storage?).to be true
        end
      end
    end
  end

  context "when merging models with metadata" do
    it "sets creator if target doesn't have one" do
      model = create(:model, creator: create(:creator))
      target = create(:model)
      expect { target.merge!(model) }.to change(target, :creator).to(model.creator)
    end

    it "doesn't set creator if target does have one" do
      model = create(:model, creator: create(:creator))
      target = create(:model, creator: create(:creator))
      expect { target.merge!(model) }.not_to change(target, :creator)
    end

    it "sets collection if target doesn't have one" do
      model = create(:model, collection: create(:collection))
      target = create(:model)
      expect { target.merge!(model) }.to change(target, :collection).to(model.collection)
    end

    it "doesn't set collection if target does have one" do
      model = create(:model, collection: create(:collection))
      target = create(:model, collection: create(:collection))
      expect { target.merge!(model) }.not_to change(target, :collection)
    end

    it "sets license if target doesn't have one" do
      model = create(:model, license: "MIT")
      target = create(:model, license: nil)
      expect { target.merge!(model) }.to change(target, :license).to("MIT")
    end

    it "doesn't set license if target does have one" do
      model = create(:model, license: "MIT")
      target = create(:model, license: "0BSD")
      expect { target.merge!(model) }.not_to change(target, :license)
    end

    it "merges tags from both" do
      model = create(:model, tag_list: ["tag3", "tag4"])
      target = create(:model, tag_list: ["tag1", "tag2"])
      target.merge!(model)
      expect(target.tag_list).to contain_exactly("tag1", "tag2", "tag3", "tag4")
    end

    it "merges links from both" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      model = create(:model, links_attributes: [{url: "https://manyfold.app"}, {url: "https://example.com"}])
      target = create(:model, links_attributes: [{url: "https://bbc.co.uk"}, {url: "https://example.com"}])
      target.merge!(model)
      expect(target.links.count).to eq 3
      expect(target.links.map(&:url)).to include "https://manyfold.app"
      expect(target.links.map(&:url)).to include "https://bbc.co.uk"
    end
  end

  context "when merging with duplicate filenames" do
    let(:model) { create(:model) }
    let(:target) { create(:model) }

    it "renames incoming file to avoid conflict if files are different" do # rubocop:disable RSpec/MultipleExpectations
      create(:model_file, model: model, filename: "test.stl", digest: "abcd")
      create(:model_file, model: target, filename: "test.stl", digest: "1234")
      target.merge!(model)
      expect(target.model_files.map(&:filename)).to contain_exactly("test_abcd.stl", "test.stl")
    end

    it "discards incoming file if they are identical" do
      create(:model_file, model: model, filename: "test.stl", digest: "abcd")
      create(:model_file, model: target, filename: "test.stl", digest: "abcd")
      expect { target.merge!(model) }.not_to change { target.model_files.count }
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

  context "when organizing" do
    around do |ex|
      Dir.mktmpdir do |library_path|
        @library_path = library_path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:model) {
      FileUtils.mkdir_p(File.join(library.path, "original"))
      m = create(:model, library: library, name: "test model", path: "original", tag_list: [])
      create(:model_file, model: m)
      m
    }

    it "moves model folder" do # rubocop:todo RSpec/MultipleExpectations
      expect { model.organize! }.not_to raise_error
      expect(Dir.exist?(File.join(library.path, "original"))).to be false
      expect(Dir.exist?(File.join(library.path, "@untagged", "test-model##{model.id}"))).to be true
    end

    it "has a validation error if the destination path already exists, and does not move anything" do # rubocop:todo RSpec/MultipleExpectations
      FileUtils.mkdir_p(File.join(library.path, "@untagged/test-model##{model.id}"))
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
      create(:admin) # We need a user for permission setting
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

    it "copies permissions" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      member_role = Role.find_by(name: :member)
      model.revoke_permission("view", member_role)
      new_model = model.split! files: [model.model_files.first]
      expect(model.caber_relations.count).to eq 1
      expect(new_model.caber_relations.count).to eq 1
      model.caber_relations.each do |relation|
        expect(new_model.grants_permission_to?(relation.permission, relation.subject)).to be true
      end
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

    it "calls destroy on files" do # rubocop:todo RSpec/ExampleLength
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
    it "writes datapackage if model has changed" do
      model = create(:model)
      expect { model.update(name: "Changed") }.to have_enqueued_job(UpdateDatapackageJob).with(model.id)
    end

    it "doesn't update datapackage if model didn't actually change" do
      model = create(:model)
      expect { model.update(name: model.name) }.not_to have_enqueued_job(UpdateDatapackageJob)
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
    expect(model.file_extensions).to contain_exactly("obj", "stl")
  end

  context "when adding links" do
    let(:url) { "https://example.com" }
    let(:model) { create(:model, links_attributes: [{url: url}]) }

    it "adds unique links" do
      opts = {links_attributes: [{url: "https://new.url.com"}]}
      expect { model.update! opts }.to change { model.links.count }.from(1).to(2)
    end

    it "doesn't add duplicate links" do
      opts = {links_attributes: [{url: url}]}
      expect { model.update! opts }.not_to change { model.links.count }
    end

    it "filters duplicate links without raising an error" do
      opts = {links_attributes: [{url: url}]}
      expect { model.update! opts }.not_to raise_error
    end
  end

  context "when creating a model" do
    it "queues model publish activity job if the model is public" do
      expect {
        create(:model, :public)
      }.to have_enqueued_job(Activity::ModelPublishedJob).once
    end

    it "doesn't queue any activity jobs if the model isn't public" do
      expect {
        create(:model)
      }.not_to have_enqueued_job(Activity::ModelPublishedJob)
    end
  end

  context "when making a model public" do
    let!(:model) { create(:model, license: nil) }

    before do
      model.clear_changes_information
      model.update(caber_relations_attributes: [{subject: nil, permission: "view"}])
      model.validate
    end

    it "requires a creator" do
      expect(model.errors[:creator]).to include "can't be blank"
    end

    it "make creators public" do
      new_creator = create(:creator)
      model.update!(creator: new_creator, license: "MIT")
      expect(new_creator).to be_public
    end

    it "requires a license" do
      expect(model.errors[:license]).to include "can't be blank"
    end

    it "doesn't make model public if validation failed" do
      expect(model.reload.public?).to be false
    end
  end

  context "when updating a private model" do
    let!(:model) { create(:model, creator: create(:creator, :public)) }

    before do
      model.clear_changes_information
    end

    it "doesn't queue any activity jobs" do
      expect {
        model.update!(caption: "new caption!")
      }.not_to have_enqueued_job(Activity::ModelUpdatedJob)
    end

    it "queues publish activity job if the model was just made public" do
      expect {
        model.update!(caber_relations_attributes: [{subject: nil, permission: "view"}])
      }.to have_enqueued_job(Activity::ModelPublishedJob).once
    end
  end

  context "when updating a public model" do
    let!(:model) { create(:model, :public) }

    before do
      model.clear_changes_information
    end

    it "queues update activity job" do
      expect {
        model.update!(caption: "new caption!")
      }.to have_enqueued_job(Activity::ModelUpdatedJob).once
    end

    it "doesn't queue any activity jobs if the update isn't noteworthy" do
      expect {
        model.update(path: "test")
      }.not_to have_enqueued_job(Activity::ModelUpdatedJob)
    end

    it "queues publish activity job if the creator was changed to a public one" do
      expect {
        model.update!(creator: create(:creator, :public))
      }.to have_enqueued_job(Activity::ModelPublishedJob).once
    end

    it "queues collected activity job if the collection was changed to a public one" do
      expect {
        model.update!(collection: create(:collection, :public))
      }.to have_enqueued_job(Activity::ModelCollectedJob).once
    end

    it "queues normal update activity job if the collection was changed to a private one" do
      expect {
        model.update!(collection: create(:collection))
      }.to have_enqueued_job(Activity::ModelUpdatedJob).once
    end
  end

  context "when downloading remote files", :thingiverse_api_key, :vcr do
    let(:model) { create(:model) }

    context "without an existing file", vcr: {cassette_name: "models/model/new_file_success"} do
      let(:add_new_file) {
        model.create_or_update_file_from_url(
          url: "https://raw.githubusercontent.com/Buildbee/example-stl/refs/heads/main/binary_cube.stl",
          filename: "binary_cube.stl"
        )
      }

      it "adds a new file" do
        expect { add_new_file }.to change { model.model_files.count }.by(1)
      end

      it "stores ETag" do
        file = add_new_file
        expect(file.attachment.metadata["remote_etag"]).to eq "W/\"357a8d67199ae2dcd1933fbd1fbd0bcee7b6a1aa26f284333e7e09a7f0248ab4\""
      end

      it "updated changed time on model" do
        expect { add_new_file }.to change(model, :updated_at)
      end
    end

    context "with an existing file, unchanged on remote", vcr: {cassette_name: "models/model/unchanged_file_success"} do
      let(:update_file) {
        model.create_or_update_file_from_url(
          url: "https://raw.githubusercontent.com/Buildbee/example-stl/refs/heads/main/binary_cube.stl",
          filename: "binary_cube.stl"
        )
      }

      before do
        file = create(:model_file, model: model, filename: "binary_cube.stl")
        file.attachment_attacher.add_metadata("remote_etag" => "W/\"357a8d67199ae2dcd1933fbd1fbd0bcee7b6a1aa26f284333e7e09a7f0248ab4\"")
        file.save!
      end

      it "doesn't add a new file" do
        expect { update_file }.not_to change { model.model_files.count }
      end

      it "doesn't change the file" do
        expect { update_file }.not_to change { model.model_files.first.updated_at }
      end

      it "doesn't change the model" do
        expect { update_file }.not_to change(model, :updated_at)
      end
    end

    context "with an existing file, changed on remote", vcr: {cassette_name: "models/model/changed_file_success"} do
      let(:update_file) {
        model.create_or_update_file_from_url(
          url: "https://raw.githubusercontent.com/Buildbee/example-stl/refs/heads/main/binary_cube.stl",
          filename: "binary_cube.stl"
        )
      }

      before do
        file = create(:model_file, model: model, filename: "binary_cube.stl", created_at: 1.week.ago, updated_at: 1.week.ago)
        file.attachment_attacher.add_metadata("remote_etag" => "W/\"outdated_etag\"")
        file.save!(touch: false)
      end

      it "doesn't add a new file" do
        expect { update_file }.not_to change { model.model_files.count }
      end

      it "does change the file" do
        expect { update_file }.to change { model.model_files.first.updated_at }
      end

      it "does change the model" do
        expect { update_file }.to change(model, :updated_at)
      end

      it "stores the new etag" do
        file = update_file
        expect(file.attachment.metadata["remote_etag"]).to eq "W/\"357a8d67199ae2dcd1933fbd1fbd0bcee7b6a1aa26f284333e7e09a7f0248ab4\""
      end
    end
  end
end
