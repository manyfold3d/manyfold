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
      expect(described_class.new.folders_with_changes(library)).to contain_exactly("thingiverse_model")
    end

    it "doesn't detect changes because of incorrect file in images folder" do
      create(:model_file, model: model, filename: "files/part_one.stl") # We already know about the correct file
      expect(described_class.new.folders_with_changes(library)).to be_empty
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
      expect(described_class.new.filenames_on_disk(library)).not_to include "model/.hidden.stl"
    end

    it "does not include hidden folder contents in file list" do
      expect(described_class.new.filenames_on_disk(library)).not_to include "model/.git/file.stl"
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
      expect(described_class.new.filenames_on_disk(library)).not_to include "wrong.stl"
    end

    it "does include files within directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).to include "wrong.stl/file.stl"
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
      expect(described_class.new.filenames_on_disk(library)).to include "model/file.obj"
    end

    it "detects uppercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include "model/file.OBJ"
    end

    it "detects mixed case file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include "model/file.Obj"
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
      expect(described_class.new.filenames_on_disk(library)).to include "model [test]/file.obj"
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

  context "performance optimizations" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_two/part_1.obj",
        "model_three/part_1.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "uses eager loading to avoid N+1 queries when getting known filenames" do
      # Create several models with files
      3.times do |i|
        model = create(:model, library: library, path: "model_#{i + 1}")
        create(:model_file, model: model, filename: "part_1.obj")
      end

      # Count queries during known_filenames call
      query_count = 0
      query_counter = lambda do |_name, _started, _finished, _unique_id, payload|
        query_count += 1 unless payload[:name] == "SCHEMA" || payload[:sql].include?("sqlite_master")
      end

      ActiveSupport::Notifications.subscribed(query_counter, "sql.active_record") do
        described_class.new.known_filenames(library)
      end

      # Should be 2 queries (1 for model_files, 1 for eager loaded models), not 3+ N+1 queries
      expect(query_count).to be <= 2
    end

    it "processes files in batches to manage memory" do
      job = described_class.new

      # Mock to verify batching happens
      allow(job).to receive(:filenames_on_disk).and_return((1..2500).map { |i| "model/file#{i}.stl" })
      allow(job).to receive(:known_filenames).and_return([])

      # Verify that each_slice is called (batching mechanism)
      expect_any_instance_of(Array).to receive(:each_slice).with(described_class::BATCH_SIZE).and_call_original # rubocop:disable RSpec/AnyInstance

      job.folders_with_changes(library)
    end
  end
end
