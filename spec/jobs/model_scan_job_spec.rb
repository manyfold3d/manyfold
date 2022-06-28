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
      expect(ModelScanJob.file_pattern).to eq "*.{stl,STL,obj,OBJ,3mf,3MF,blend,BLEND,mix,MIX,ply,PLY,jpg,JPG,png,PNG}"
    end

    it "can scan a library directory" do
      expect { ModelScanJob.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.model_files.map(&:filename)).to eq ["part_1.obj", "part_2.obj"]
    end

    it "can scan a thingiverse-structured model" do
      thing = create(:model, path: "thingiverse_model", library: library)
      expect { ModelScanJob.perform_now(thing) }.to change { thing.model_files.count }.to(1)
      expect(thing.model_files.first.filename).to eq "files/part_one.stl"
    end

    it "sets the preview file to the first scanned file by default" do
      expect { ModelScanJob.perform_now(model) }.to change { model.model_files.count }.to(2)
      expect(model.preview_file.filename).to eq "part_1.obj"
    end
  end

  context "with already scanned files" do
    it "removes files that don't exist on disk" do
      thing = create(:model, path: "thingiverse_model", library: library)
      create(:model_file, filename: "missing.stl", model: thing)
      create(:model_file, filename: "gone.stl", model: thing)
      expect { ModelScanJob.perform_now(thing) }.to change { thing.model_files.count }.from(2).to(1)
      expect(thing.model_files.first.filename).to eq "files/part_one.stl"
    end

    it "does not recreate parts that have been merged into other models" do
      # Set up one model nested inside another
      model_one = create(:model, path: "model_one", library: library)
      ModelScanJob.perform_now(model_one)
      nested_model = create(:model, path: "model_one/nested_model", library: library)
      ModelScanJob.perform_now(nested_model)
      # Check initial conditions
      expect(Model.count).to eq 2
      expect(ModelFile.count).to eq 3
      expect(model_one.model_files.count).to eq 2
      expect(nested_model.model_files.count).to eq 1
      # Merge the models
      nested_model.merge_into! model_one
      # Check that worked
      expect(Model.count).to eq 1
      expect(ModelFile.count).to eq 3
      expect(model_one.model_files.count).to eq 3
      # Now recreate the nested model and rescan
      nested_model = create(:model, path: "model_one/nested_model", library: library)
      ModelScanJob.perform_now(nested_model)
      # That should not have changed anything apart from creating an empty model which will be cleaned up later
      expect(Model.count).to eq 1
      expect(ModelFile.count).to eq 3
      expect(model_one.model_files.count).to eq 3
      expect(nested_model.model_files.count).to eq 0
    end
  end
end
