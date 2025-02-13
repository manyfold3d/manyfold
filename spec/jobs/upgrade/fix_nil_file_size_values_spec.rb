# frozen_string_literal: true

require "rails_helper"
require "support/mock_directory"

RSpec.describe Upgrade::FixNilFileSizeValues do
  it 'updates file with nil size' do
    library = create(:library, path: Rails.root.join("spec/fixtures"))
    model1 = create(:model, library: library, path: "fix_nil_file_size_values_spec")
    part = create(:model_file, model: model1, filename: "example.obj", size: 284)
    part.update(size: nil)
    described_class.perform_now
    part.reload
    expect(part.size).to_not eq(nil)
  end
end
