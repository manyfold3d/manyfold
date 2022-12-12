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
end
