# frozen_string_literal: true

require "rails_helper"
require "support/mock_directory"

RSpec.describe Problems::Nesting do
  around do |ex|
    MockDirectory.create([
      "parent/parent_part.stl",
      "parent/child/child_part.stl"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
  let!(:parent) { create(:model, library: library, path: "parent") }
  let!(:child) { create(:model, library: library, path: "parent/child") }

  before do
    create(:model_file, model: parent, filename: "parent_part.stl")
    create(:model_file, model: child, filename: "child_part.stl")
  end

  def create_nesting_problem
    create(:problem_on_model, category: :nesting, problematic: parent)
  end

  it "destroys the Problem row after a successful merge" do
    problem = create_nesting_problem
    problem_id = problem.id

    result = described_class.new.resolve!(problem, action: :merge)

    expect(result).to eq(removed: true)
    expect(Problem.unscoped.where(id: problem_id)).not_to exist
    expect(MergeHistory.where(target_model: parent).count).to eq 1
    expect(Model.where(id: child.id)).not_to exist
  end

  it "persists merge and destroys the Problem when uniqueness Redlock would raise" do
    problem = create_nesting_problem
    problem_id = problem.id
    stub_unique_enqueue_redlock_error

    expect { Problem.resolve_batch([problem]) }.not_to raise_error

    expect(Problem.unscoped.where(id: problem_id)).not_to exist
    expect(MergeHistory.where(target_model: parent).count).to eq 1
    expect(Model.where(id: child.id)).not_to exist
  end
end
