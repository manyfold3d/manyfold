require "rails_helper"
require "support/mock_directory"

RSpec.describe ModelFile do
  it_behaves_like "Listable"

  it "is not valid without a filename" do
    expect(build(:model_file, filename: nil)).not_to be_valid
  end

  it "is not valid without being part of a model" do
    expect(build(:model_file, model: nil)).not_to be_valid
  end

  it "is valid if it has a filename and model" do
    expect(build(:model_file)).to be_valid
  end

  it "must have a unique filename within its model" do
    model = create(:model, path: "model")
    create(:model_file, model: model, filename: "part.stl")
    expect(build(:model_file, model: model, filename: "part.stl")).not_to be_valid
  end

  it "can have the same filename as a file in a different model" do
    library = create(:library)
    model1 = create(:model, library: library, path: "model1")
    create(:model_file, model: model1, filename: "part.stl")
    model2 = create(:model, library: library, path: "model2")
    expect(build(:model_file, model: model2, filename: "part.stl")).to be_valid
  end

  context "with a real model" do
    let(:library) { create(:library, path: Rails.root.join("spec/fixtures")) }
    let(:model) { create(:model, library: library, path: "model_file_spec") }
    let(:part) {
      create(
        :model_file,
        model: model,
        filename: "example.obj",
        attachment: ModelFileUploader.upload(File.open("spec/fixtures/model_file_spec/example.obj"), :cache)
      )
    }

    it "calculates dimensions of model" do
      expect(part.dimensions).to eq(Mittsu::Vector3.new(10, 15, 20))
    end

    it "calculates file size when attached" do
      expect(part.size).to eq(284)
    end

    it "calculates digest for a file" do
      expect(part.calculate_digest.first(16)).to eq("8a0f188378204b67")
    end

    it "uses streaming when calculating digest to avoid loading entire file into memory" do
      # Mock the IO to verify we're reading in chunks rather than all at once
      io_mock = double("io")
      allow(io_mock).to receive(:read).with(8192).and_return("chunk1", "chunk2", nil)
      allow(part.attachment).to receive(:open).and_yield(io_mock)

      digest = part.calculate_digest
      expect(digest).to be_a(String)
      expect(digest.length).to eq(128) # SHA512 hex digest length
      expect(io_mock).to have_received(:read).with(8192).at_least(3).times
    end
  end

  it "finds duplicate files using digest" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model")
    part1 = create(:model_file, model: model, filename: "same.obj", digest: "1234")
    part2 = create(:model_file, model: model, filename: "same.stl", digest: "1234")
    create(:model_file, model: model, filename: "different.stl", digest: "4321")
    allow(part1).to receive(:size).and_return(123)
    expect(part1.duplicate?).to be true
    expect(part1.duplicates).to contain_exactly(part2)
  end

  it "does not flag duplicates for nil digests" do # rubocop:todo RSpec/ExampleLength
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model1")
    part1 = create(:model_file, model: model, filename: "nil.obj", digest: nil)
    create(:model_file, model: model, filename: "nil.stl", digest: nil)
    expect(part1.duplicate?).to be false
  end

  it "does not flag duplicates for zero-length files" do # rubocop:todo RSpec/ExampleLength
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model1")
    part1 = create(:model_file, model: model, filename: "same.obj", digest: "1234")
    create(:model_file, model: model, filename: "same.stl", digest: "1234")
    allow(part1).to receive(:size).and_return(0)
    expect(part1.duplicate?).to be false
  end

  describe ".batch_find_duplicates" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    it "efficiently detects duplicates for multiple files in batch" do
      library = create(:library, path: Rails.root.join("/tmp"))
      model = create(:model, library: library, path: "model1")

      # Create files: two duplicates and one unique
      file1 = create(:model_file, model: model, filename: "dup1.stl", digest: "abc123", size: 1000)
      file2 = create(:model_file, model: model, filename: "dup2.stl", digest: "abc123", size: 1000)
      file3 = create(:model_file, model: model, filename: "unique.stl", digest: "xyz789", size: 2000)

      result = ModelFile.batch_find_duplicates([file1.id, file2.id, file3.id])

      expect(result[file1.id]).to be true   # Is a duplicate
      expect(result[file2.id]).to be true   # Is a duplicate
      expect(result[file3.id]).to be false  # Is unique
    end

    it "handles empty file list" do
      result = ModelFile.batch_find_duplicates([])
      expect(result).to eq({})
    end

    it "excludes zero-length files from duplicates" do
      library = create(:library, path: Rails.root.join("/tmp"))
      model = create(:model, library: library, path: "model1")

      file1 = create(:model_file, model: model, filename: "empty1.stl", digest: "abc123", size: 0)
      file2 = create(:model_file, model: model, filename: "empty2.stl", digest: "abc123", size: 0)

      result = ModelFile.batch_find_duplicates([file1.id, file2.id])

      expect(result[file1.id]).to be false
      expect(result[file2.id]).to be false
    end

    it "excludes document files from duplicates" do
      library = create(:library, path: Rails.root.join("/tmp"))
      model = create(:model, library: library, path: "model1")

      # Document files (.pdf, .txt, etc.) should not be flagged as duplicates
      file1 = create(:model_file, model: model, filename: "readme.pdf", digest: "abc123", size: 1000)
      file2 = create(:model_file, model: model, filename: "license.pdf", digest: "abc123", size: 1000)

      result = ModelFile.batch_find_duplicates([file1.id, file2.id])

      expect(result[file1.id]).to be false
      expect(result[file2.id]).to be false
    end
  end

  it "mtime reports attachment modified time" do
    file = create(:model_file)
    expect(file.mtime).to be_present
  end

  it "mtime reports updated time if attachment has no mtime metadata" do
    file = create(:model_file)
    allow(file).to receive(:attachment).and_return(double(mtime: nil)) # rubocop:disable RSpec/VerifiedDoubles
    expect(file.mtime).to be_present
  end

  it "mtime reports updated time if there is no attachment" do
    file = create(:model_file)
    allow(file).to receive(:attachment).and_return(nil)
    expect(file.mtime).to be_present
  end

  it "ctime reports attachment created time" do
    file = create(:model_file)
    expect(file.ctime).to be_present
  end

  it "mtime reports created time if attachment has no ctime metadata" do
    file = create(:model_file)
    allow(file).to receive(:attachment).and_return(double(ctime: nil)) # rubocop:disable RSpec/VerifiedDoubles
    expect(file.ctime).to be_present
  end

  it "ctime reports created time if there is no attachment" do
    file = create(:model_file)
    allow(file).to receive(:attachment).and_return(nil)
    expect(file.ctime).to be_present
  end

  context "with actual files on disk" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.3mf"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let(:model) { create(:model, library: library, path: "model_one") }
    let(:file) { create(:model_file, model: model, filename: "part_1.3mf", digest: "1234") }

    it "renames file on disk" do # rubocop:disable RSpec/MultipleExpectations
      file.update!(filename: "newname.3mf")
      expect(File.exist?(File.join(library.path, "model_one/part_1.3mf"))).to be false
      expect(File.exist?(File.join(library.path, "model_one/newname.3mf"))).to be true
    end

    it "rejects filename change if MIME type would change" do # rubocop:disable RSpec/MultipleExpectations
      file.update(filename: "part_1.stl")
      expect(file).not_to be_valid
      expect(file.errors[:filename].first).to eq "is not the same file type"
    end

    it "rejects case-only filename change" do # rubocop:disable RSpec/MultipleExpectations
      file.update(filename: "part_1.3MF")
      expect(file).not_to be_valid
      expect(file.errors[:filename].first).to eq "cannot be a case-only change"
    end

    it "removes original file from disk when explicitly told to" do
      expect { file.delete_from_disk_and_destroy }.to(
        change { File.exist?(File.join(library.path, file.path_within_library)) }.from(true).to(false)
      )
    end

    it "does not remove original file from disk when destroyed" do
      expect { file.destroy }.not_to(
        change { File.exist?(File.join(library.path, file.path_within_library)) }
      )
    end

    it "ignores missing files on deletion" do
      file.update_attribute :filename, "gone.3mf" # rubocop:disable Rails/SkipsModelValidations
      expect { file.destroy }.not_to raise_exception
    end

    it "queues up rescans for duplicates on destroy" do
      dupe = create(:model_file, model: model, filename: "duplicate.3mf", digest: "1234")
      expect { file.destroy }.to(
        have_enqueued_job(Analysis::AnalyseModelFileJob).with(dupe.id)
      )
    end
  end

  context "with different versions of the same file" do
    let!(:model) { create(:model) }
    let!(:presupported) { create(:model_file, model: model, presupported: true) }
    let!(:unsupported) { create(:model_file, model: model, presupported: false, presupported_version: presupported) }

    it "can access supported part from unsupported part" do
      expect(unsupported.presupported_version).to eq presupported
    end

    it "can access unsupported part from presupported part" do
      expect(presupported.unsupported_version).to eq unsupported
    end

    it "only let presupported files be set as the presupported_version" do # rubocop:todo RSpec/MultipleExpectations
      another_unsupported = create(:model_file, model: model, presupported: false)
      unsupported.presupported_version = another_unsupported
      expect(unsupported).not_to be_valid
      expect(unsupported.errors[:presupported_version].first).to eq "is not a presupported file"
    end

    it "does not allow a presupported_version to be set for presupported files" do # rubocop:todo RSpec/MultipleExpectations
      another_presupported = create(:model_file, model: model, presupported: true)
      presupported.presupported_version = another_presupported
      expect(presupported).not_to be_valid
      expect(presupported.errors[:presupported_version].first).to eq "cannot be set on a presupported file"
    end

    it "clears presupported version if presupported file is set to unsupported" do
      presupported.update!(presupported: false)
      expect(unsupported.reload.presupported_version).to be_nil
    end
  end

  {
    stl: true,
    png: false,
    pdf: false,
    lys: false
  }.each_pair do |extension, result|
    it "shows that #{extension} files are#{"n't" if result == false} renderable" do
      file = create(:model_file, filename: "test.#{extension}")
      expect(file.is_renderable?).to be result
    end
  end

  [true, false].each do |state|
    before do
      allow(SiteSettings).to receive_messages(default_indexable: state, default_ai_indexable: state)
    end

    let(:model) { create(:model) }
    let(:file) { create(:model_file, model: model) }

    it "delegates indexable to model (#{state})" do
      expect(file.indexable?).to eq model.indexable?
    end

    it "delegates AI indexable to model (#{state})" do
      expect(file.ai_indexable?).to eq model.ai_indexable?
    end
  end
end
