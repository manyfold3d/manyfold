require "rails_helper"

RSpec.describe Library do
  context "when being validated" do
    around do |ex|
      MockDirectory.create([]) do |path|
        @library_path = path
        ex.run
      end
    end

    it "is not valid without a path" do
      expect(build(:library, path: nil)).not_to be_valid
    end

    it "is valid if a path is specified" do
      expect(build(:library, path: @library_path)).to be_valid # rubocop:todo RSpec/InstanceVariable
    end

    it "is invalid if a bad path is specified" do # rubocop:todo RSpec/MultipleExpectations
      l = build(:library, path: "/nope", create_path_if_not_on_disk: "0")
      expect(l).not_to be_valid
      expect(l.errors[:path].first).to eq "must be writable"
    end

    it "has many models" do
      expect(build(:library).models).to eq []
    end

    it "must have a unique path" do
      create(:library, path: @library_path) # rubocop:todo RSpec/InstanceVariable
      expect(build(:library, path: @library_path)).not_to be_valid # rubocop:todo RSpec/InstanceVariable
    end

    [
      "/bin",
      "/boot",
      "/dev",
      "/etc",
      "/lib",
      "/lost",
      "/proc",
      "/root",
      "/run",
      "/sbin",
      "/selinux",
      "/srv",
      "/usr"
    ].each do |prefix|
      it "disallows paths under #{prefix}" do
        path = File.join(prefix, "library")
        allow(File).to receive(:exist?).with(path).and_return(true)
        library = build(:library, path: path)
        library.valid?
        expect(library.errors[:path]).to include "cannot be a privileged system path"
      end
    end

    it "allows paths that *begin* with a filtered path" do
      library = build(:library, path: "/libraries")
      library.valid?
      expect(library.errors[:path]).not_to include "cannot be a privileged system path"
    end

    it "disallows root folder" do
      library = build(:library, path: "/")
      library.valid?
      expect(library.errors[:path]).to include "cannot be a privileged system path"
    end

    it "disallows read-only folders" do
      path = "/readonly/library"
      allow(FileTest).to receive(:exist?).with(path).and_return(true)
      library = build(:library, path: path)
      library.valid?
      expect(library.errors[:path]).to include "must be writable"
    end

    it "normalizes paths" do
      path = Rails.root + "tmp/../app"
      library = build(:library, path: path)
      expect(library.path).to eq (Rails.root + "app").to_s
    end
  end

  context "when using a folder containing files" do
    around do |ex|
      MockDirectory.create([
        "3dmodels/model [escapetest]/part_1.obj"
      ]) do |path|
        @library_path = path + "/3dmodels"
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "lists files" do
      expect(library.list_files("**/*")).not_to be_empty
    end
  end

  context "when using a folder with a space in" do
    around do |ex|
      MockDirectory.create([
        "3d models/model [escapetest]/part_1.obj"
      ]) do |path|
        @library_path = path + "/3d models"
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "lists files" do
      expect(library.list_files("**/*")).not_to be_empty
    end
  end

  context "when listing a folder with manyfold-specific data in" do
    around do |ex|
      MockDirectory.create([
        "3d/model/part_1.png",
        "3d/model/.manyfold/derivatives/part_1.png/preview.png"
      ]) do |path|
        @library_path = path + "/3d"
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "lists valid files" do
      expect(library.list_files("**/*")).to include "model/part_1.png"
    end

    it "ignores manyfold-specific files" do
      expect(library.list_files("**/*")).not_to include "model/.manyfold/derivatives/part_1.png/preview.png"
    end
  end

  it "is valid if path can be created" do # rubocop:todo RSpec/MultipleExpectations
    library = build(:library, path: "/tmp/libraries/subdirectory", create_path_if_not_on_disk: "1")
    expect(library).to be_valid
    expect(Dir).to exist(library.path)
  end

  context "when deleting libraries" do
    around do |ex|
      MockDirectory.create([
        "model/file.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let(:model) { create(:model, path: "model", library: library) }
    let!(:file) { create(:model_file, filename: "file.stl", model: model) } # rubocop:disable RSpec/LetSetup

    it "removes associated Models" do
      expect { library.destroy }.to change(Model, :count).from(1).to(0)
    end

    it "removes associated ModelFiles" do
      expect { library.destroy }.to change(ModelFile, :count).from(1).to(0)
    end

    it "preserves files on disk" do # rubocop:disable RSpec/MultipleExpectations
      expect(File.exist?(File.join(@library_path, "model/file.stl"))).to be true # rubocop:todo RSpec/InstanceVariable
      expect { library.destroy }.not_to change { File.exist?(File.join(@library_path, "model/file.stl")) } # rubocop:todo RSpec/InstanceVariable
    end
  end

  context "when attempting to create one library inside another" do
    subject(:library) { build(:library, path: outer_library.path + "/nested_library") }

    let(:outer_library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    around do |ex|
      MockDirectory.create([
        "nested_library/model/model.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    it "does not validate" do
      expect(library).not_to be_valid
    end

    it "displays a useful error message" do
      library.validate
      expect(library.errors[:path].first).to eq "cannot be inside another library"
    end
  end

  context "when attempting to create one library outside another" do
    subject(:library) { build(:library, path: nested_library.path.gsub("/nested_library", "")) }

    let(:nested_library) { create(:library, path: @library_path + "/nested_library") } # rubocop:todo RSpec/InstanceVariable

    around do |ex|
      MockDirectory.create([
        "nested_library/model/model.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    it "does not validate" do
      expect(library).not_to be_valid
    end

    it "displays a useful error message" do
      library.validate
      expect(library.errors[:path].first).to eq "cannot contain other libraries"
    end
  end

  context "with multiple libraries" do
    let!(:first_library) { create(:library) }
    let!(:second_library) { create(:library) }

    it "uses first library as default if not explicitly set" do
      expect(described_class.default).to eq first_library
    end

    it "uses second library as default if explicitly set" do
      SiteSettings.default_library = second_library.id
      expect(described_class.default).to eq second_library
    end

    it "falls back to first library as default if previous default is removed" do
      SiteSettings.default_library = second_library.id
      second_library.destroy
      expect(described_class.default).to eq first_library
    end

    it "explicitly resets default library if default is destroyed (second)" do
      SiteSettings.default_library = second_library.id
      second_library.destroy
      expect(SiteSettings.default_library).to eq first_library.id
    end

    it "explicitly resets default library if default is destroyed (first)" do
      SiteSettings.default_library = first_library.id
      first_library.destroy
      expect(SiteSettings.default_library).to eq second_library.id
    end

    it "explicitly resets default library to nil if all libraries are destroyed" do
      SiteSettings.default_library = first_library.id
      first_library.destroy
      second_library.destroy
      expect(SiteSettings.default_library).to be_nil
    end
  end
end
