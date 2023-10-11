require "rails_helper"

RSpec.describe ProblemsHelper do
  let(:model) { create(:model) }

  it "converts a problem to a severity level" do
    expect(helper.problem_severity(
      Problem.new(category: :duplicate, problematic: model)
    )).to eq "warning"
  end

  it "works out the maximum severity from a set of problems (warning)" do
    Problem.create(category: :duplicate, problematic: model)
    Problem.create(category: :inefficient, problematic: model)
    expect(helper.max_problem_severity).to eq "warning"
  end

  it "works out the maximum severity from a set of problems (danger)" do
    Problem.create(category: :missing, problematic: model)
    Problem.create(category: :duplicate, problematic: model)
    Problem.create(category: :inefficient, problematic: model)
    expect(helper.max_problem_severity).to eq "danger"
  end
end
