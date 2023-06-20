require "rails_helper"
require "support/mock_directory"

RSpec.describe ModelScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:library) do
    create(:library, path: Rails.root.join("spec/fixtures/library"))
  end

  let(:model) do
    create(:model, path: "model_one", library: library)
  end

  context "but no scanned files" do
    it "can scan a library directory" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.model_files.map(&:filename)).to eq ["part_1.obj", "part_2.obj"]
    end

    it "can scan a thingiverse-structured model" do
      thing = create(:model, path: "thingiverse_model", library: library)
      expect { described_class.perform_now(thing) }.to change { thing.model_files.count }.to(2)
      expect(thing.model_files.map(&:filename)).to eq ["files/part_one.stl", "images/card_preview_DISPLAY.png"]
    end

    it "sets the preview file to the first scanned file by default" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.preview_file.filename).to eq "part_1.obj"
    end

    it "queues up individual file scans" do
      expect { described_class.perform_now(model) }.to have_enqueued_job(ModelFileScanJob).exactly(2).times
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
