# frozen_string_literal: true

require "rails_helper"
require "support/mock_directory"

RSpec.describe Upgrade::FixNilFileSizeValues do
  let(:library) { create(:library, path: Rails.root.join("spec/fixtures")) }
  let(:model1) { create(:model, library: library, path: "fix_nil_file_size_values_spec") }
  let(:part) { create(:model_file, model: model1, filename: "example.obj", size: 284) }

  it "updates file with nil size" do
    part.update(size: nil)
    described_class.perform_sync
    part.reload
    expect(part.size).not_to be_nil
  end
end
