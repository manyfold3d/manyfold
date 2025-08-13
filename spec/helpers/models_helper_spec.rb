require "rails_helper"

RSpec.describe ModelsHelper do
  describe "string concat" do
    let(:files) do
      %w[
        armleft
        arm_right
        head_1
        leg_l
        leg_r
      ].map { |it| build(:model_file, filename: "#{it}.stl") }
    end

    it "groups strings together with similar prefixes" do # rubocop:todo RSpec/MultipleExpectations
      groups = helper.group(files)
      expect(groups["leg_"].count).to eq(2)
      expect(groups["arm"].count).to eq(2)
      expect(groups[nil].count).to eq(1)
    end
  end

  describe "license options" do
    it "creates a suitable hash of options" do
      expect(helper.license_select_options).to include('<option value="CC0-1.0">Creative Commons Zero</option>')
    end

    it "includes CERN licenses" do
      expect(helper.license_select_options).to include('<option value="CERN-OHL-S-2.0">CERN Open Hardware Licence Version 2 - Strongly Reciprocal</option>')
    end

    it "sets selected option" do
      expect(helper.license_select_options(selected: "CC0-1.0")).to include('<option selected="selected" value="CC0-1.0">Creative Commons Zero</option>')
    end
  end
end
