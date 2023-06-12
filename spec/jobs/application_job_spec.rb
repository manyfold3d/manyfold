require "rails_helper"

RSpec.describe ApplicationJob do
  it "generates a case-insensitive pattern for all supported files" do
    pattern = described_class.file_pattern
    expect(pattern).to include "[Ss][Tt][Ll],"
    expect(pattern).to include "[Pp][Nn][Gg],"
  end

  it "generates a case-insensitive pattern for image files" do
    pattern = described_class.image_pattern
    expect(pattern).not_to include "[Ss][Tt][Ll],"
    expect(pattern).to include "[Pp][Nn][Gg],"
  end
end
