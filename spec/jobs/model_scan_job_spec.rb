require "rails_helper"

RSpec.describe ModelScanJob, type: :job do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:library) do
    create(:library, path: File.join(Rails.root, "spec", "fixtures", "library"))
  end

  let(:model) do
    create(:model, path: "model_one", library: library)
  end

  context "but no scanned files" do
    it "generates a case-insensitive pattern for files" do
      expect(ModelScanJob.file_pattern).to eq "*.{stl,STL,obj,OBJ,3mf,3MF,blend,BLEND,mix,MIX,ply,PLY,jpg,JPG,png,PNG,jpeg,JPEG,gif,GIF,svg,SVG}"
    end

    it "can scan a library directory" do
      expect { ModelScanJob.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.model_files.map(&:filename)).to eq ["part_1.obj", "part_2.obj"]
    end

    it "can scan a thingiverse-structured model" do
      thing = create(:model, path: "thingiverse_model", library: library)
      expect { ModelScanJob.perform_now(thing) }.to change { thing.model_files.count }.to(2)
      expect(thing.model_files.map(&:filename)).to eq ["files/part_one.stl", "images/card_preview_DISPLAY.png"]
    end

    it "sets the preview file to the first scanned file by default" do
      expect { ModelScanJob.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.preview_file.filename).to eq "part_1.obj"
    end

    it "queues up individual file scans" do
      expect { ModelScanJob.perform_now(model) }.to have_enqueued_job(ModelFileScanJob).exactly(2).times
    end

    it "destroys itself if empty on scan" do
      empty = create(:model, path: "empty_model", library: library)
      expect { ModelScanJob.perform_now(empty) }.to change { library.models.count }.from(1).to(0)
    end
  end

  context "with already scanned files" do
    it "removes files that don't exist on disk" do
      thing = create(:model, path: "model_one/nested_model", library: library)
      create(:model_file, filename: "missing.stl", model: thing)
      create(:model_file, filename: "gone.stl", model: thing)
      expect { ModelScanJob.perform_now(thing) }.to change { thing.model_files.count }.from(2).to(1)
      expect(thing.model_files.first.filename).to eq "part_one.stl"
    end
  end
end
