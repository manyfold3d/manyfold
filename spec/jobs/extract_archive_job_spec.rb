require "rails_helper"

RSpec.describe ExtractArchiveJob do
  subject(:job) { described_class.new }

  let(:model) { create(:model) }

  it "extracts files" do # rubocop:todo RSpec/ExampleLength,RSpec/MultipleExpectations
    Tempfile.create(%w[test .zip]) do |file|
      Zip::File.open(file, create: true) do |zipfile|
        zipfile.get_output_stream("test.stl") { |f| f.puts "solid" }
      end
      model_file = model.model_files.create(filename: "test.zip", attachment: Rack::Test::UploadedFile.new(file))
      expect { described_class.perform_now(model_file.id) }.to change(ModelFile, :count).by(1)
      expect(File.size(model.model_files.last.attachment)).to eq 6
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
      model_file = model.model_files.create(filename: "test.zip", attachment: Rack::Test::UploadedFile.new(file))
      described_class.perform_now(model_file.id, remove_when_complete: true)
      model.reload
      expect(model.model_files.count).to eq 2
      expect(model.model_files.map(&:filename)).to contain_exactly("one/test.stl", "two/more.stl")
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
      model_file = model.model_files.create(filename: "test.zip", attachment: Rack::Test::UploadedFile.new(file))
      described_class.perform_now(model_file.id, remove_when_complete: true)
      model.reload
      expect(model.model_files.count).to eq 2
      expect(model.model_files.map(&:filename)).to contain_exactly("folder/test2.stl", "test.stl")
    end
  end

  it "handles files in root and single subfolder" do # rubocop:todo RSpec/ExampleLength,RSpec/MultipleExpectations
    Tempfile.create(%w[test .zip]) do |file|
      Zip::File.open(file, create: true) do |zipfile|
        zipfile.mkdir("subfolder")
        zipfile.get_output_stream("test.stl") { |f| f.puts "solid" }
        zipfile.get_output_stream("subfolder/more.stl") { |f| f.puts "solid" }
      end
      model_file = model.model_files.create(filename: "test.zip", attachment: Rack::Test::UploadedFile.new(file))
      described_class.perform_now(model_file.id, remove_when_complete: true)
      model.reload
      expect(model.model_files.count).to eq 2
      expect(model.model_files.map(&:filename)).to contain_exactly("subfolder/more.stl", "test.stl")
    end
  end
end
