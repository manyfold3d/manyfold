require "rails_helper"

describe ModelFilePolicy::Scope do
  subject(:scope) { described_class.new(user, model.model_files) }

  let(:model) { create(:model) }
  let!(:previewable_file) { create(:model_file, model: model, previewable: true) }
  let!(:private_file) { create(:model_file, model: model) }

  context "with public preview permission granted" do
    let(:user) { nil }

    before do
      model.grant_permission_to "preview", nil
    end

    it "includes previewable file" do
      expect(scope.resolve).to include previewable_file
    end

    it "doesn't include private file" do
      expect(scope.resolve).not_to include private_file
    end
  end

  context "with no public permission granted" do
    let(:user) { nil }

    it "doesn't include previewable file" do
      expect(scope.resolve).not_to include previewable_file
    end

    it "doesn't include private file" do
      expect(scope.resolve).not_to include private_file
    end
  end
end
