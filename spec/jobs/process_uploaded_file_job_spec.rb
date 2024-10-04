require "rails_helper"

RSpec.describe ProcessUploadedFileJob do
  subject(:job) { described_class.new }

  context "when counting common path prefixes" do
    it "returns zero if there are no directories at all" do
      expect(job.send(:count_common_elements, [])).to eq 0
    end

    it "returns zero if there are no common prefixes" do
      expect(job.send(:count_common_elements, [
        ["folder1"],
        ["folder2"],
        []
      ])).to eq 0
    end

    it "returns the number of common prefixes if present" do
      expect(job.send(:count_common_elements, [
        ["root", "sub", "folder1"],
        ["root", "sub", "folder2"]
      ])).to eq 2
    end

    it "returns correct count where all prefixes are the same" do
      expect(job.send(:count_common_elements, [
        ["root", "sub", "folder"],
        ["root", "sub", "folder"]
      ])).to eq 3
    end

    it "returns correct count where a common folder has a subfolder" do
      expect(job.send(:count_common_elements, [
        ["root", "sub"],
        ["root", "sub", "folder2"]
      ])).to eq 2
    end

    it "returns zero for *some* common prefixes but not on everything" do
      expect(job.send(:count_common_elements, [
        ["folder1", "sub1"],
        ["folder1", "sub2"],
        ["folder2", "sub1"]
      ])).to eq 0
    end
  end

  context "when uploading a file" do
    let!(:admin) { create(:admin) }
    let(:uploader) { create(:contributor) }
    let(:library) { create(:library) }
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new("solid\n"), original_filename: "test.stl") }

    it "Creates a new model" do
      expect { job.perform(library.id, file) }.to change(Model, :count).by(1)
    end

    it "Sets default owner permission if no owner set" do
      job.perform(library.id, file)
      expect(Model.last.permitted_users.with_permission(:own)).to include admin
    end

    it "Sets owner permission to provided user" do
      job.perform(library.id, file, owner: uploader)
      expect(Model.last.permitted_users.with_permission(:own)).to include uploader
    end

    it "Stores creator if provided" do
      creator = create(:creator)
      job.perform(library.id, file, creator_id: creator.id)
      expect(Model.last.creator).to eq creator
    end

    it "Stores collection if provided" do
      collection = create(:collection)
      job.perform(library.id, file, collection_id: collection.id)
      expect(Model.last.collection).to eq collection
    end

    it "Stores license if provided" do
      job.perform(library.id, file, license: "CC-BY-NC-SA-4.0")
      expect(Model.last.license).to eq "CC-BY-NC-SA-4.0"
    end

    it "Stores tags if provided" do
      job.perform(library.id, file, tags: "tag1, tag2, tag3")
      expect(Model.last.tag_list).to eq ["tag1", "tag2", "tag3"]
    end

    it "sets path using auto-organize" do
      job.perform(library.id, file, tags: "tag1")
      expect(Model.last.path).to eq "tag1/test#1"
    end

    it "queues up model scan" do
      expect { job.perform(library.id, file) }.to have_enqueued_job(ModelScanJob).once
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

    it "queues up file scan" do
      expect { job.perform(library.id, file, model: model) }.to have_enqueued_job(ModelFileScanJob).once
    end
  end

  context "when errors occur during processing" do
    let(:library) { create(:library) }
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new, original_filename: "test.zip") }

    it "removes the created model" do # rubocop:todo RSpec/ExampleLength
      job = described_class.new
      allow(job).to receive(:unzip).and_raise(StandardError)
      expect {
        begin
          job.perform(library.id, file)
        rescue
          nil
        end
      }.not_to change(Model, :count)
    end

    it "leaves the uploaded file in place"
  end

  context "when extracting a zip file" do
    let(:model) { create(:model) }

    it "extracts files" do # rubocop:todo RSpec/ExampleLength
      Tempfile.create(%w[test .zip]) do |file|
        Zip::File.open(file, create: true) do |zipfile|
          zipfile.get_output_stream("test.stl") { |f| f.puts "solid" }
        end
        upload = Rack::Test::UploadedFile.new(file)
        expect { described_class.new.send(:unzip, model, upload) }.to change(ModelFile, :count).by(1)
      end
    end

    it "extracts subfolders" do # rubocop:todo RSpec/ExampleLength,RSpec/MultipleExpectations
      Tempfile.create(%w[test .zip]) do |file|
        Zip::File.open(file, create: true) do |zipfile|
          zipfile.mkdir("one")
          zipfile.mkdir("two")
          zipfile.get_output_stream("one/test.stl") { |f| f.puts "solid" }
          zipfile.get_output_stream("two/more.stl") { |f| f.puts "solid" }
        end
        described_class.new.send(:unzip, model, Rack::Test::UploadedFile.new(file))
        expect(model.model_files.count).to be 2
        expect(model.model_files.map(&:filename).sort).to eq ["one/test.stl", "two/more.stl"]
      end
    end

    it "strips common subfolders" do # rubocop:todo RSpec/ExampleLength,RSpec/MultipleExpectations
      Tempfile.create(%w[test .zip]) do |file|
        Zip::File.open(file, create: true) do |zipfile|
          zipfile.mkdir("sub")
          zipfile.mkdir("sub/folder")
          zipfile.get_output_stream("sub/test.stl") { |f| f.puts "solid" }
          zipfile.get_output_stream("sub/folder/test2.stl") { |f| f.puts "solid" }
        end
        described_class.new.send(:unzip, model, Rack::Test::UploadedFile.new(file))
        expect(model.model_files.count).to eq 2
        expect(model.model_files.map(&:filename).sort).to eq ["folder/test2.stl", "test.stl"]
      end
    end

    it "handles files in root and single subfolder" do # rubocop:todo RSpec/ExampleLength,RSpec/MultipleExpectations
      Tempfile.create(%w[test .zip]) do |file|
        Zip::File.open(file, create: true) do |zipfile|
          zipfile.mkdir("subfolder")
          zipfile.get_output_stream("test.stl") { |f| f.puts "solid" }
          zipfile.get_output_stream("subfolder/more.stl") { |f| f.puts "solid" }
        end
        described_class.new.send(:unzip, model, Rack::Test::UploadedFile.new(file))
        expect(model.model_files.count).to eq 2
        expect(model.model_files.map(&:filename).sort).to eq ["subfolder/more.stl", "test.stl"]
      end
    end
  end
end
