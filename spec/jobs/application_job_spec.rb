require "rails_helper"

RSpec.describe ApplicationJob do
  it "generates a case-insensitive pattern for all supported files" do
    pattern = described_class.file_pattern
    expect(pattern).to include "stl,STL"
    expect(pattern).to include "png,PNG"
  end

  it "generates a case-insensitive pattern for iamge files" do
    pattern = described_class.image_pattern
    expect(pattern).not_to include "stl,STL"
    expect(pattern).to include "png,PNG"
  end
end
