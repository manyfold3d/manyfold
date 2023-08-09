require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::CheckModelIntegrityJob do
  around do |ex|
    MockDirectory.create([
      "model_one/test.stl"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  # rubocop:disable RSpec/InstanceVariable
  let(:library) { create(:library, path: @library_path) }
  # rubocop:enable RSpec/InstanceVariable

  it "flags models with no folder as a problem" do
    model = create(:model, library: library, path: "missing")
    expect { described_class.perform_now(model.id) }.to change(Problem, :count).from(0).to(2)
    expect(model.problems.map(&:category)).to eq ["missing", "empty"]
  end

  it "flags up problems for files that don't exist on disk" do
    thing = create(:model, path: "model_one", library: library)
    create(:model_file, filename: "missing.stl", model: thing)
    expect { described_class.perform_now(thing.id) }.to change(Problem, :count).from(0).to(1)
    expect(thing.model_files.first.problems.first.category).to eq "missing"
  end
end
