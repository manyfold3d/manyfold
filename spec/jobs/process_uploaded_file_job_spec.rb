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
end
