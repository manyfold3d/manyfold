require "rails_helper"

RSpec.describe SupportedMimeTypes do
  it "includes STL files in model list" do
    expect(described_class.model_types).to include("model/stl")
    expect(described_class.model_extensions).to include("stl")
  end

  it "includes PNG files in image list" do
    expect(described_class.image_types).to include("image/png")
    expect(described_class.image_extensions).to include("png")
  end

  it "includes alternative extensions for same type" do
    expect(described_class.model_extensions).to include("lys")
    expect(described_class.model_extensions).to include("lyt")
  end

  context "when listing non-standard model files" do
    it "includes OpenSCAD" do
      expect(described_class.model_types).to include("application/x-openscad")
      expect(described_class.model_extensions).to include("scad")
    end

    it "includes GCode" do
      expect(described_class.model_types).to include("text/x-gcode")
      expect(described_class.model_extensions).to include("gcode")
    end
  end
end
