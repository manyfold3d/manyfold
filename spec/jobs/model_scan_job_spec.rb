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
      # TODO maybe: nested models only worked because scan wasn't recursive - ugh
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(3)
      expect(model.model_files.map(&:filename)).to eq ["nested_model/part_one.stl","part_1.obj", "part_2.obj"]
    end

    it "can scan a thingiverse-structured model" do
      thing = create(:model, path: "thingiverse_model", library: library)
      # TODO maybe: how did ignore.stl get ignored before?
      expect { described_class.perform_now(thing) }.to change { thing.model_files.count }.to(5)
      expect(thing.model_files.map(&:filename)).to eq ["LICENSE.txt", "README.txt", "files/part_one.stl", "images/card_preview_DISPLAY.png", "images/ignore.stl"]
    end

    it "sets the preview file to the first scanned file by default" do
      expect { described_class.perform_now(model) }.to change { model.model_files.count }.to(3)
      # TODO maybe: probably should test for grabbing a jpg.   should prefer grabbing something at top level and not presupported
      expect(model.preview_file.filename).to eq "nested_model/part_one.stl"
    end

    it "queues up individual file scans" do
      expect { described_class.perform_now(model) }.to have_enqueued_job(ModelFileScanJob).exactly(3).times
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
