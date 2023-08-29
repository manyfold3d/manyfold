require "rails_helper"

RSpec.describe Problem, type: :model do
  describe "#method_name" do
    context "when condition A" do
      it "returns expected result" do
        problem = create(:problem)
        result = problem.method_name
        expect(result).to eq(expected_result)
      end
    end

    context "when condition B" do
      it "returns expected result" do
        problem = create(:problem)
        result = problem.method_name
        expect(result).to eq(expected_result)
      end
    end
  end
end
