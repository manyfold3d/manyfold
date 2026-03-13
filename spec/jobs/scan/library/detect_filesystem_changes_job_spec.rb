require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::Library::DetectFilesystemChangesJob do
  context "with files in various folders" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/part_2.obj",
        "subfolder/model_two/part_one.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "can scan a library directory" do # rubocop:todo RSpec/MultipleExpectations
      described_class.perform_now(library.id)
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one")
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "subfolder/model_two")
    end

    it "only scans models with changes on rescan" do
      model_one = create(:model, path: "model_one", library: library)
      Scan::Model::AddNewFilesJob.perform_now(model_one.id)
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "subfolder/model_two").exactly(1).times
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

    it "pulls out nested model as separate" do # rubocop:todo RSpec/MultipleExpectations
      described_class.perform_now(library.id)
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one")
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one/nested")
    end
  end

  context "with a thingiverse-style model folder" do
    around do |ex|
      MockDirectory.create([
        "thingiverse_model/files/part_one.stl",
        "thingiverse_model/images/preview.png",
        "thingiverse_model/README.txt"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "thingiverse_model").exactly(1).times
    end
  end

  context "with model folders that contain some common subfolders" do
    around do |ex|
      MockDirectory.create([
        "model/presupported/part_one.stl",
        "model/unsupported/part_one.stl",
        "model/supported/part_one.stl",
        "model/parts/part_one.stl",
        "model/files/part_one.stl",
        "model/images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "model").exactly(1).times
    end
  end

  context "with model folders that contain some common subfolders with mixed case" do
    around do |ex|
      MockDirectory.create([
        "model/Presupported/part_one.stl",
        "model/UnSupported/part_one.stl",
        "model/Supported/part_one.stl",
        "model/Parts/part_one.stl",
        "model/Files/part_one.stl",
        "model/Images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "ignores case and filters out subfolders correctly" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "model").exactly(1).times
    end
  end

  context "with a space in the library folder name" do
    around do |ex|
      MockDirectory.create([
        "3d models/model_one/part_1.obj",
        "3d models/model_one/part_2.obj",
        "3d models/subfolder/model_two/part_one.stl"
      ]) do |path|
        @library_path = path + "/3d models"
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "can scan a library directory" do # rubocop:todo RSpec/MultipleExpectations
      described_class.perform_now(library.id)
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one")
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "subfolder/model_two")
    end
  end
end
