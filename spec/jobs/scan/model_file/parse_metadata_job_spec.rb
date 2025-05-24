require "rails_helper"

RSpec.describe Scan::ModelFile::ParseMetadataJob do
  let(:file) { create(:model_file) }
  let(:supported_file) { create(:model_file, filename: "file1_supported.stl") }
  let(:image_file) { create(:model_file, filename: "preview.jpg") }
  let(:doc_file) { create(:model_file, filename: "README.txt") }

  it "detects if file is presupported" do
    described_class.perform_now(supported_file.id)
    supported_file.reload
    expect(supported_file.presupported).to be true
  end

  it "detects if file is unsupported" do
    described_class.perform_now(file.id)
    file.reload
    expect(file.presupported).to be false
  end

  it "sets images as previewable" do
    described_class.perform_now(image_file.id)
    image_file.reload
    expect(image_file.previewable).to be true
  end

  it "defaults models to not be previewable" do
    described_class.perform_now(file.id)
    file.reload
    expect(file.previewable).to be false
  end

  it "queues analysis job" do
    expect { described_class.perform_now(file.id) }.to have_enqueued_job(Analysis::AnalyseModelFileJob).once
  end

  it "works for non-model and non-image files" do
    expect { described_class.perform_now(doc_file.id) }.to have_enqueued_job(Analysis::AnalyseModelFileJob).once
  end

  it "raises exception if file ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
