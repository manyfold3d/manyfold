require "rails_helper"

RSpec.describe ModelsHelper do
  describe "string concat" do
    let(:files) do
      %w[
        foo
        bar
        foobar
        foo_bar
        bar_foo
      ].map { |x| build(:model_file, filename: "#{x}.stl") }
    end

    it "groups strings together with similar prefixes" do
      groups = helper.group(files)
      expect(groups["foo"].count).to eq(2)
      expect(groups["bar"].count).to eq(2)
      expect(groups[nil].count).to eq(1)
    end
  end

  describe "license options" do
    it "creates a suitable hash of options" do
      expect(helper.license_select_options).to include('<option value="CC0-1.0">Creative Commons Zero v1.0 Universal (CC0-1.0)</option>')
    end

    it "sets selected option" do
      expect(helper.license_select_options(selected: "CC0-1.0")).to include('<option selected="selected" value="CC0-1.0">Creative Commons Zero v1.0 Universal (CC0-1.0)</option>')
    end
  end
end
