require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::CheckModelIntegrityJob do
  let(:library) do
    create(:library, path: Rails.root.join("spec/fixtures/library"))
  end

  it "flags models with no folder as a problem" do
    lib = create(:library, path: File.join("/", "tmp"))
    model = create(:model, library: lib, path: "missing")
    expect { described_class.perform_now(model) }.to change(Problem, :count).from(0).to(2)
    expect(model.problems.first.category).to eq "missing"
    expect(model.problems.last.category).to eq "empty"
  end

  it "flags up problems for files that don't exist on disk" do
    thing = create(:model, path: "model_one/nested_model", library: library)
    create(:model_file, filename: "missing.stl", model: thing)
    create(:model_file, filename: "gone.stl", model: thing)
    expect { described_class.perform_now(thing) }.to change(Problem, :count).from(0).to(2)
    expect(thing.model_files.first.problems.first.category).to eq "missing"
  end
end
