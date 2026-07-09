require "rails_helper"

RSpec.describe AddUploadedFileToModelJob do
  subject(:job) { described_class.new }

  context "when uploading a file" do
    let(:uploader) { create(:contributor) }
    let(:model) { create(:model) }
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new("solid\n"), original_filename: "test.stl") }

    it "adds the file to the model" do
      expect { job.perform(model.id, file) }.to change(model.model_files, :count).by(1)
    end

    it "doesn't increase model count if uploading the same filename" do
      create(:model_file, model: model, filename: "test.stl")
      expect { job.perform(model.id, file) }.not_to change(model.model_files, :count)
    end

    it "overwrites existing file with the same filename" do
      create(:model_file, model: model, filename: "test.stl")
      expect { job.perform(model.id, file) }.to change { model.model_files.first.attachment.read }.to("solid\n")
    end

    it "promotes the file to proper storage" do
      job.perform(model.id, file)
      expect(model.model_files.last.attachment.storage_key).to eq :library_1
    end

    it "queues up file metadata parsing" do
      expect { job.perform(model.id, file) }.to have_enqueued_job(Scan::ModelFile::ParseMetadataJob).once
    end
  end

  context "when extracting a zip file" do
    let(:upload) { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "test.zip") }
    let(:model) { create(:model) }

    it "adds file to model" do
      expect { job.perform(model.id, upload) }.to change(ModelFile, :count).by(1)
    end

    it "queues up extraction job" do
      expect { job.perform(model.id, upload) }.to have_enqueued_job(ExtractArchiveJob).once
    end
  end
end
