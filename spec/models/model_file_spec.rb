require "rails_helper"
require "support/mock_directory"

RSpec.describe ModelFile do
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

  it "calculates a bounding box for model" do
    library = create(:library, path: Rails.root.join("spec/fixtures"))
    model1 = create(:model, library: library, path: "model_file_spec")
    part = create(:model_file, model: model1, filename: "example.obj")
    expect(part.bounding_box).to eq([10, 15, 20])
  end

  it "finds duplicate files using digest" do
    library = create(:library, path: Rails.root.join("/tmp"))
    model1 = create(:model, library: library, path: "model1")
    part1 = create(:model_file, model: model1, filename: "file.obj", digest: "1234")
    model2 = create(:model, library: library, path: "model2")
    part2 = create(:model_file, model: model2, filename: "file.stl", digest: "1234")
    model3 = create(:model, library: library, path: "model3")
    create(:model_file, model: model3, filename: "file.stl", digest: "4321")
    expect(part1.duplicate?).to be true
    expect(part1.duplicates).to eq [part2]
  end

  context "with actual files on disk" do
    before do
      ActiveJob::Base.queue_adapter = :test
    end

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
    let(:file) { create(:model_file, model: model, filename: "part_1.3mf", digest: "1234") }

    it "removes original file from disk" do
      expect { file.delete_from_disk_and_destroy }.to(
        change { File.exist?(file.pathname) }.from(true).to(false)
      )
    end

    it "ignores missing files on deletion" do
      file.update! filename: "gone.3mf"
      expect { file.delete_from_disk_and_destroy }.not_to raise_exception
    end

    it "calls standard destroy" do
      allow(file).to receive(:destroy)
      file.delete_from_disk_and_destroy
      expect(file).to have_received(:destroy).once
    end

    it "queues up rescans for duplicates on destroy" do
      dupe = create(:model_file, model: model, filename: "duplicate.3mf", digest: "1234")
      expect { file.delete_from_disk_and_destroy }.to(
        have_enqueued_job(Scan::AnalyseModelFileJob).with(dupe.id)
      )
    end
  end
end
