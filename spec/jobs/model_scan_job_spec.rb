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

  it "can scan a library directory" do
    expect { ModelScanJob.perform_now(model) }.to change { model.parts.count }.to(2)
    expect(model.parts.map(&:filename)).to eq ["part_1.obj", "part_2.obj"]
  end

  it "can scan a thingiverse-structured model" do
    thing = create(:model, path: "thingiverse_model", library: library)
    expect { ModelScanJob.perform_now(thing) }.to change { thing.parts.count }.to(1)
    expect(thing.parts.first.filename).to eq "files/part_one.stl"
  end

  it "sets the preview part to the first scanned part by default" do
    expect { ModelScanJob.perform_now(model) }.to change { model.parts.count }.to(2)
    expect(model.preview_part.filename).to eq "part_1.obj"
  end

end
