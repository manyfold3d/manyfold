require "rails_helper"

RSpec.describe ProcessUploadedFileJob do
  subject(:job) { described_class.new }

  context "when uploading a file", :after_first_run do
    let(:uploader) { create(:contributor) }
    let(:library) { create(:library) }
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new("solid\n"), original_filename: "test.stl") }

    it "Creates a new model" do
      expect { job.perform(library.id, file) }.to change(Model, :count).by(1)
    end

    it "has no owner if no owner is explicitly set" do
      job.perform(library.id, file)
      expect(Model.last.owners).to be_empty
    end

    it "Sets owner permission to provided user" do
      job.perform(library.id, file, owner: uploader)
      expect(Model.last.owners).to include uploader
    end

    it "Sets default visibility even if a owner is provided" do
      allow(SiteSettings).to receive(:default_viewer_role).and_return("member")
      job.perform(library.id, file, owner: uploader)
      expect(Model.last.permitted_roles.with_permission(:view)).to include Role.find_by(name: "member")
    end

    it "Stores creator if provided" do
      creator = create(:creator)
      job.perform(library.id, file, creator_id: creator.id)
      expect(Model.last.creator).to eq creator
    end

    it "Stores collection if provided" do
      collection = create(:collection)
      job.perform(library.id, file, collection_ids: [collection.id])
      expect(Model.last.collections).to include collection
    end

    it "Stores multiple collections if provided"

    it "Stores license if provided" do
      job.perform(library.id, file, license: "CC-BY-NC-SA-4.0")
      expect(Model.last.license).to eq "CC-BY-NC-SA-4.0"
    end

    it "Stores tags if provided" do
      job.perform(library.id, file, tag_list: "tag1, tag2, tag3")
      expect(Model.last.tag_list).to contain_exactly("tag1", "tag2", "tag3")
    end

    it "sets path using auto-organize" do
      job.perform(library.id, file, tag_list: "tag1")
      m = Model.last
      expect(m.path).to eq "tag1/test##{m.id}"
    end

    it "queues up model new file scan" do
      expect { job.perform(library.id, file) }.to have_enqueued_job(Scan::Model::AddNewFilesJob).once
    end
  end

  context "when uploading a file to an existing model" do
    let(:uploader) { create(:contributor) }
    let(:library) { create(:library) }
    let!(:model) { create(:model, library: library) }
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new("solid\n"), original_filename: "test.stl") }

    it "doesn't create a new model" do
      expect { job.perform(library.id, file, model: model) }.not_to change(Model, :count)
    end

    it "adds the file to the model" do
      expect { job.perform(library.id, file, model: model) }.to change(model.model_files, :count).by(1)
    end

    it "doesn't increase model count if uploading the same filename" do
      create(:model_file, model: model, filename: "test.stl")
      expect { job.perform(library.id, file, model: model) }.not_to change(model.model_files, :count)
    end

    it "overwrites existing file with the same filename" do
      create(:model_file, model: model, filename: "test.stl")
      expect { job.perform(library.id, file, model: model) }.to change { model.model_files.first.attachment.read }.to("solid\n")
    end

    it "promotes the file to proper storage" do
      job.perform(library.id, file, model: model)
      expect(model.model_files.last.attachment.storage_key).to eq :library_1
    end

    it "queues up file metadata parsing" do
      expect { job.perform(library.id, file, model: model) }.to have_enqueued_job(Scan::ModelFile::ParseMetadataJob).once
    end
  end

  context "when extracting a zip file" do
    let(:library) { create(:library) }
    let(:upload) { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "test.zip") }

    it "adds file to model" do
      expect { job.perform(library.id, upload) }.to change(ModelFile, :count).by(1)
    end

    it "queues up extraction job" do
      expect { job.perform(library.id, upload) }.to have_enqueued_job(ExtractArchiveJob).once
    end
  end
end
