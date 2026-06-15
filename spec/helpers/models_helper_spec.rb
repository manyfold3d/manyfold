require "rails_helper"

RSpec.describe ModelsHelper do
  describe "string concat" do
    let(:files) do
      %w[
        armleft.stl
        arm_right.stl
        head_1.stl
        leg_l.stl
        leg_r.stl
        model.stl
        model.stp
      ].map { build(:model_file, filename: it) }
    end

    it "groups strings together with similar prefixes" do # rubocop:todo RSpec/MultipleExpectations
      groups = helper.group(files)
      expect(groups["leg_"].count).to eq(2)
      expect(groups["arm"].count).to eq(2)
      expect(groups["model"].count).to eq(2)
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
