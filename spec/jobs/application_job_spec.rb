require "rails_helper"

RSpec.describe ApplicationJob do
  it "generates a case-insensitive pattern for all supported files" do # rubocop:todo RSpec/MultipleExpectations
    pattern = described_class.file_pattern
    expect(pattern).to include "[Ss][Tt][Ll],"
    expect(pattern).to include "[Pp][Nn][Gg],"
  end

  it "generates a case-insensitive pattern for image files" do # rubocop:todo RSpec/MultipleExpectations
    pattern = described_class.image_pattern
    expect(pattern).not_to include "[Ss][Tt][Ll],"
    expect(pattern).to include "[Pp][Nn][Gg],"
  end
end
