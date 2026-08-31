require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::Library::DetectFilesystemChangesJob do
  # INIT-016/SPEC-002: discover now writes last_detect_at; clear between examples so
  # earlier watermarks cannot mtime-prune a fresh MockDirectory tree.
  after do
    Rails.cache.delete_matched("manyfold:scan:library:*:last_filesystem_detect_at")
  rescue NotImplementedError, NoMethodError
    # MemoryStore / FileStore without delete_matched — clear the whole store.
    Rails.cache.clear
  end

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
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "subfolder/model_two", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CheckMissingFilesJob).to have_been_enqueued.with(library.id, hash_including(scan_batch_id: kind_of(String)))
    end

    it "only scans models with changes on rescan" do
      model_one = create(:model, path: "model_one", library: library)
      Scan::Model::AddNewFilesJob.perform_now(model_one.id)
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "subfolder/model_two", hash_including(scan_batch_id: kind_of(String))).exactly(1).times
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
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one/nested", hash_including(scan_batch_id: kind_of(String)))
    end

    context "with existing model" do
      before do
        model = create(:model, library: library, path: "model_one")
        create(:model_file, model: model, filename: "part_1.obj")
        create(:model_file, model: model, filename: "nested/part_2.obj")
      end

      it "does not pick up already-merged subfolder" do
        expect(described_class.new.folders_with_changes(library)).to be_empty
      end
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
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "thingiverse_model", hash_including(scan_batch_id: kind_of(String))).exactly(1).times
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
        "kit/presupported/part_one.stl",
        "kit/unsupported/part_one.stl",
        "kit/supported/part_one.stl",
        "kit/parts/part_one.stl",
        "kit/files/part_one.stl",
        "kit/images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "kit", hash_including(scan_batch_id: kind_of(String))).exactly(1).times
    end
  end

  context "with model folders that contain some common subfolders with mixed case" do
    around do |ex|
      MockDirectory.create([
        "kit/Presupported/part_one.stl",
        "kit/UnSupported/part_one.stl",
        "kit/Supported/part_one.stl",
        "kit/Parts/part_one.stl",
        "kit/Files/part_one.stl",
        "kit/Images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "ignores case and filters out subfolders correctly" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(Scan::Library::CreateModelFromPathJob).with(library.id, "kit", hash_including(scan_batch_id: kind_of(String))).exactly(1).times
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
      expect(described_class.new.folders_with_changes(library)).not_to include "model"
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
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "model_one", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "subfolder/model_two", hash_including(scan_batch_id: kind_of(String)))
    end
  end

  context "with depth-3 Category/Creator/Model layout" do
    around do |ex|
      MockDirectory.create([
        "Cults3D/Abe3D/Mystique/part.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "discovers models deeper than Category/Model" do
      expect { described_class.perform_now(library.id) }
        .to have_enqueued_job(Scan::Library::CreateModelFromPathJob)
        .with(library.id, "Cults3D/Abe3D/Mystique", hash_including(scan_batch_id: kind_of(String)))
    end
  end

  context "with new files in an existing model" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/part_2.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let!(:model) do
      m = create(:model, path: "model_one", library: library)
      create(:model_file, model: m, filename: "part_1.obj")
      m
    end

    it "enqueues AddNewFiles for the known model instead of CreateModel" do
      expect { described_class.perform_now(library.id) }
        .to have_enqueued_job(Scan::Model::AddNewFilesJob)
        .with(model.id, hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).not_to have_been_enqueued.with(library.id, "model_one", anything)
    end
  end

  context "with a symlink escaping the library root" do
    around do |ex|
      MockDirectory.create([
        "safe_model/part.stl"
      ]) do |path|
        @library_path = path
        outside = File.join(File.dirname(path), "outside_escape")
        FileUtils.mkdir_p(outside)
        File.write(File.join(outside, "secret.stl"), "x")
        File.symlink(outside, File.join(path, "escape_link"))
        ex.run
      ensure
        FileUtils.rm_rf(outside) if outside && File.exist?(outside)
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "does not treat symlink targets outside the library as models" do
      described_class.perform_now(library.id)
      expect(Scan::Library::CreateModelFromPathJob).to have_been_enqueued.with(library.id, "safe_model", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).not_to have_been_enqueued.with(library.id, "escape_link", anything)
    end
  end

  # INIT-016/SPEC-002 — mtime prune, path_prefixes, uniqueness fingerprint, CheckMissing skip
  describe "mtime prune on discover" do
    around do |ex|
      MockDirectory.create([
        "CategoryA/ModelOld/part.stl",
        "CategoryB/ModelNew/part.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "skips untouched Category trees when last_detect_at is set" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      watermark = 1.hour.ago
      Rails.cache.write(
        "manyfold:scan:library:#{library.id}:last_filesystem_detect_at",
        watermark,
        expires_in: 30.days
      )

      old = 2.hours.ago.to_time
      FileUtils.touch(File.join(@library_path, "CategoryA"), mtime: old) # rubocop:todo RSpec/InstanceVariable
      FileUtils.touch(File.join(@library_path, "CategoryA", "ModelOld"), mtime: old) # rubocop:todo RSpec/InstanceVariable
      FileUtils.touch(File.join(@library_path, "CategoryA", "ModelOld", "part.stl"), mtime: old) # rubocop:todo RSpec/InstanceVariable

      fresh = Time.current.to_time
      FileUtils.touch(File.join(@library_path, "CategoryB"), mtime: fresh) # rubocop:todo RSpec/InstanceVariable
      FileUtils.touch(File.join(@library_path, "CategoryB", "ModelNew"), mtime: fresh) # rubocop:todo RSpec/InstanceVariable
      FileUtils.touch(File.join(@library_path, "CategoryB", "ModelNew", "part.stl"), mtime: fresh) # rubocop:todo RSpec/InstanceVariable

      expect { described_class.perform_now(library.id) }
        .to have_enqueued_job(Scan::Library::CreateModelFromPathJob)
        .with(library.id, "CategoryB/ModelNew", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).not_to have_been_enqueued
        .with(library.id, "CategoryA/ModelOld", anything)
    end
  end

  describe "path_prefixes scoping" do
    around do |ex|
      MockDirectory.create([
        "KeepMe/ModelOne/part.stl",
        "SkipMe/ModelTwo/part.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "only enqueues CreateModelFromPath under the given prefixes" do
      expect { described_class.perform_now(library.id, path_prefixes: ["KeepMe"]) }
        .to have_enqueued_job(Scan::Library::CreateModelFromPathJob)
        .with(library.id, "KeepMe/ModelOne", hash_including(scan_batch_id: kind_of(String)))
      expect(Scan::Library::CreateModelFromPathJob).not_to have_been_enqueued
        .with(library.id, "SkipMe/ModelTwo", anything)
    end

    it "skips library-wide CheckMissingFiles when path_prefixes are present" do
      described_class.perform_now(library.id, path_prefixes: ["KeepMe"])
      expect(Scan::Library::CheckMissingFilesJob).not_to have_been_enqueued
    end

    it "still enqueues CheckMissingFiles on unscoped detect" do
      described_class.perform_now(library.id)
      expect(Scan::Library::CheckMissingFilesJob).to have_been_enqueued
        .with(library.id, hash_including(scan_batch_id: kind_of(String)))
    end
  end

  describe "path_prefixes escape rejection" do
    around do |ex|
      MockDirectory.create([
        "safe/model/part.stl"
      ]) do |path|
        @library_path = path
        outside = File.join(File.dirname(path), "outside_escape")
        FileUtils.mkdir_p(outside)
        File.write(File.join(outside, "secret.stl"), "x")
        File.symlink(outside, File.join(path, "escape_link"))
        @outside = outside
        ex.run
      ensure
        FileUtils.rm_rf(@outside) if @outside && File.exist?(@outside)
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "rejects .. absolute and symlink-escape prefixes" do
      detector = Scan::Library::FilesystemChangeDetector.new(status: {})
      sanitized = detector.sanitize_path_prefixes(library, [
        "../outside",
        "/etc",
        "escape_link",
        "safe"
      ])
      expect(sanitized).to eq(["safe"])
    end

    it "does not enqueue models for rejected escape prefixes" do
      described_class.perform_now(library.id, path_prefixes: ["../outside", "/etc", "escape_link"])
      expect(Scan::Library::CreateModelFromPathJob).not_to have_been_enqueued
        .with(library.id, "escape_link", anything)
    end

    # INIT-016/SPEC-005 SEC-001: all prefixes rejected → fail closed (no whole-library walk).
    it "enqueues zero CreateModelFromPath and zero CheckMissingFiles when all prefixes are rejected" do
      expect {
        described_class.perform_now(library.id, path_prefixes: ["../outside", "/etc", "escape_link"])
      }.not_to have_enqueued_job(Scan::Library::CreateModelFromPathJob)
      expect(Scan::Library::CheckMissingFilesJob).not_to have_been_enqueued
    end
  end

  # INIT-016/SPEC-005 SEC-001 remediation
  describe "path_prefixes empty-after-sanitize fail-closed" do
    around do |ex|
      MockDirectory.create([
        "safe/model/part.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "enqueues zero CreateModelFromPath and zero CheckMissingFiles for missing prefixes" do
      expect {
        described_class.perform_now(library.id, path_prefixes: ["DoesNotExist"])
      }.not_to have_enqueued_job(Scan::Library::CreateModelFromPathJob)
      expect(Scan::Library::CheckMissingFilesJob).not_to have_been_enqueued
    end

    it "keeps a scoped lock fingerprint for lexically valid missing prefixes" do
      job = described_class.new(library.id, path_prefixes: ["DoesNotExist"])
      expect(job.lock_key_arguments.last).to start_with("scoped:")
      expect(job.lock_key_arguments.last).not_to eq("full")
    end

    it "does not walk the whole library when prefixes sanitize empty" do
      detector = Scan::Library::FilesystemChangeDetector.new(status: {})
      expect(detector.folders_with_changes(library, path_prefixes: ["DoesNotExist"])).to eq([])
      # Unscoped still discovers under the same tree ("model" is a common subfolder → path "safe").
      expect(detector.folders_with_changes(library, path_prefixes: nil)).to include("safe")
    end
  end

  describe "uniqueness scope fingerprint" do
    it "uses full for nil/empty prefixes" do
      expect(described_class.scope_lock_fingerprint(nil)).to eq("full")
      expect(described_class.scope_lock_fingerprint([])).to eq("full")
    end

    it "distinguishes scoped fingerprints from full and from each other" do
      a = described_class.scope_lock_fingerprint(["KeepMe"])
      b = described_class.scope_lock_fingerprint(["Other"])
      expect(a).to start_with("scoped:")
      expect(b).to start_with("scoped:")
      expect(a).not_to eq("full")
      expect(a).not_to eq(b)
      expect(described_class.scope_lock_fingerprint(["B", "A"]))
        .to eq(described_class.scope_lock_fingerprint(["A", "B"]))
    end

    it "builds distinct lock_key_arguments for full vs scoped jobs" do
      full = described_class.new(42)
      scoped = described_class.new(42, path_prefixes: ["KeepMe"])
      expect(full.lock_key_arguments).to eq([42, "full"])
      expect(scoped.lock_key_arguments.first).to eq(42)
      expect(scoped.lock_key_arguments.last).to start_with("scoped:")
      expect(scoped.lock_key_arguments).not_to eq(full.lock_key_arguments)
    end
  end

  describe "Library#detect_filesystem_changes_later" do
    let(:library) { create(:library) }

    it "passes path_prefixes through to the job" do
      expect {
        library.detect_filesystem_changes_later(path_prefixes: ["CategoryA"])
      }.to have_enqueued_job(described_class).with(library.id, hash_including(path_prefixes: ["CategoryA"]))
    end
  end
end
