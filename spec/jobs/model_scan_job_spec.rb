require "rails_helper"

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

  context "with already scanned files" do
    it "flags up problems for files that don't exist on disk" do
      thing = create(:model, path: "model_one/nested_model", library: library)
      create(:model_file, filename: "missing.stl", model: thing)
      create(:model_file, filename: "gone.stl", model: thing)
      expect { described_class.perform_now(thing) }.to change(Problem, :count).from(0).to(2)
    end
  end
end
