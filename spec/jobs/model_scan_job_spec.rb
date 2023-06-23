require "rails_helper"
require "support/mock_directory"

RSpec.describe ModelScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  context "with a simple model folder" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/part_2.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    let(:model) do
      create(:model, path: "model_one", library: library)
    end

    it "detects model files" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.model_files.map(&:filename)).to eq ["part_1.obj", "part_2.obj"]
    end

    it "sets the preview file to the first scanned file by default" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.preview_file.filename).to eq "part_1.obj"
    end

    it "queues up individual file scans" do
      expect { described_class.perform_now(model) }.to have_enqueued_job(ModelFileScanJob).exactly(2).times
    end
  end

  context "with a thingiverse-structured model" do
    around do |ex|
      MockDirectory.create([
        "thingiverse_model/files/part_one.stl",
        "thingiverse_model/images/card_preview_DISPLAY.png",
        "thingiverse_model/images/ignore.stl",
        "thingiverse_model/LICENSE.txt",
        "thingiverse_model/README.txt"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    before :all do
      ActiveJob::Base.queue_adapter = :test
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable
    let(:thing) { create(:model, path: "thingiverse_model", library: library) }

    it "scans files" do
      expect { described_class.perform_now(thing) }.to change { thing.model_files.count }.to(2)
      expect(thing.model_files.map(&:filename)).to eq ["files/part_one.stl", "images/card_preview_DISPLAY.png"]
    end

    it "ignores model-type files in image directory" do
      expect { described_class.perform_now(thing) }.to change { thing.model_files.count }.to(2)
      expect(thing.model_files.map(&:filename)).not_to include "images/ignore.stl"
    end
  end

  context "with files in some common subfolders" do
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

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable
    let(:model) { create(:model, path: "model", library: library) }

    it "finds all the files in the subfolders" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(6)
    end
  end

  context "with directories that look like files" do
    around do |ex|
      MockDirectory.create([
        "model/nope.stl/arm.stl",
        "model/leg.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:mock_library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "doesn't make ModelFile objects for folders" do
      model = create(:model, path: "model", library: mock_library)
      # arm.stl is in a contained model so there should be only one file in this model
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(1)
      expect(model.model_files.map(&:filename)).not_to include ["nope.stl"]
    end
  end
end
