require "rails_helper"

RSpec.describe FileHandlers::ImageMagick do
  it "loads formats" do
    expect(described_class::INPUT_TYPES).to include "png"
  end

  it "filters out non-image formats" do
    expect(described_class::INPUT_TYPES).not_to include "pdf"
  end
end
