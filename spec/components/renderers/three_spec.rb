# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Renderers::Three, type: :component do
  context "when checking renderer support"
  {
    stl: true,
    png: false,
    pdf: false,
    lys: false
  }.each_pair do |extension, result|
    it "shows that #{extension} files are#{"n't" if result == false} renderable" do
      file = create(:model_file, filename: "test.#{extension}")
      expect(described_class.supports?(file)).to be result
    end
  end
end
