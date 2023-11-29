require "rails_helper"

# Specs in this file have access to a helper object that includes
# the ProblemsHelper. For example:
#
# describe ProblemsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ProblemsHelper do
  describe '#problem_severity' do
      it 'returns "danger" for missing problems' do
        problem = Problem.new(category: :missing)
        expect(helper.problem_severity(problem)).to eq("danger")
      end
  
  describe '#max_problem_severity' do
        it 'returns "danger" when there is at least one missing problem' do
          create(:problem, category: :missing)
          expect(helper.max_problem_severity).to eq("danger")
    end

    it 'returns "warning" when there are nesting or duplicate problems but no missing ones' do
      create(:problem, category: :nesting)
      create(:problem, category: :duplicate)
      expect(helper.max_problem_severity).to eq("warning")
    end

    it 'returns "info" when there are no missing, nesting, or duplicate problems' do
      expect(helper.max_problem_severity).to eq("info")
    end
  end
    it 'returns "warning" for nesting problems' do
      problem = Problem.new(category: :nesting)
      expect(helper.problem_severity(problem)).to eq("warning")
    end

    it 'returns "warning" for duplicate problems' do
      problem = Problem.new(category: :duplicate)
      expect(helper.problem_severity(problem)).to eq("warning")
    end

    it 'returns "info" for other problems' do
      problem = Problem.new(category: :other)
      expect(helper.problem_severity(problem)).to eq("info")
    end
  end
end
