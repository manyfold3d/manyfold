require "rails_helper"

RSpec.describe ModelsHelper, type: :helper do
  describe "string concat" do
    let(:parts) do
      %w[
        foo
        bar
        foobar
        foo_bar
        bar_foo
      ].map { |x| build(:part, filename: "#{x}.stl") }
    end

    it "groups strings together with similar prefixes" do
      groups = helper.group(parts)
      expect(groups["foo"].count).to eq(2)
      expect(groups["bar"].count).to eq(2)
      expect(groups[nil].count).to eq(1)
    end
  end
end
