require "rails_helper"

RSpec.describe SupportedMimeTypes do
  it "includes STL files in model list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.model_types.map(&:to_s)).to include("model/stl")
    expect(described_class.model_extensions).to include("stl")
  end

  it "includes PNG files in image list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.image_types.map(&:to_s)).to include("image/png")
    expect(described_class.image_extensions).to include("png")
  end

  it "does not include DXF in image list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.image_types.map(&:to_s)).not_to include("image/vnd.dxf")
    expect(described_class.image_extensions).not_to include("dxf")
  end

  it "includes alternative extensions for same type" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.model_extensions).to include("lys")
    expect(described_class.model_extensions).to include("lyt")
  end

  it "includes PDF files in document list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.document_types.map(&:to_s)).to include("application/pdf")
    expect(described_class.document_extensions).to include("pdf")
  end

  it "includes TXT files in document list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.document_types.map(&:to_s)).to include("text/plain")
    expect(described_class.document_extensions).to include("txt")
  end

  it "includes HTML files in document list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.document_types.map(&:to_s)).to include("text/html")
    expect(described_class.document_extensions).to include("html")
  end

  it "includes Word docs in document list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.document_types.map(&:to_s)).to include("application/msword")
    expect(described_class.document_extensions).to include("doc")
    expect(described_class.document_types.map(&:to_s)).to include("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    expect(described_class.document_extensions).to include("docx")
  end

  it "includes video files in video list" do # rubocop:todo RSpec/MultipleExpectations
    expect(described_class.video_types.map(&:to_s)).to include("video/mp4")
    expect(described_class.video_extensions).to include("mp4")
  end

  context "when listing non-standard model files" do
    it "includes OpenSCAD" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.model_types).to include("application/x-openscad")
      expect(described_class.model_extensions).to include("scad")
    end

    it "includes GCode" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.model_types).to include("text/x-gcode")
      expect(described_class.model_extensions).to include("gcode")
    end

    it "includes DXF" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.model_types).to include("image/vnd.dxf")
      expect(described_class.model_extensions).to include("dxf")
    end
  end
end
