require "rails_helper"

RSpec.describe PathTranslation do
  let(:model) { create(:model) }

  context "when creating path from model details" do
    it "creates a formatted path" do
      expect(model.formatted_path).not_to be_nil
    end
  end
end
