require "rails_helper"

describe ModelPolicy::Scope do
  subject(:scope) { described_class.new(member, Model) }

  let(:member) { create(:user) }

  context "without sensitive content" do
    let(:model) { create(:model) }

    it "finds all" do
      expect(scope.resolve).to include model
    end

    it "finds all if public and no user" do
      model.grant_permission_to "view", nil
      scope = described_class.new(nil, Model)
      expect(scope.resolve).to include model
    end

    it "finds all if user has chose to hide sensitive content" do
      member.update sensitive_content_handling: "hide"
      expect(scope.resolve).to include model
    end
  end

  context "with sensitive content" do
    let(:model) { create(:model, sensitive: true) }

    it "finds all by default" do
      expect(scope.resolve).to include model
    end

    it "finds all if public and no user" do
      model.grant_permission_to "view", nil
      scope = described_class.new(nil, Model)
      expect(scope.resolve).to include model
    end

    it "doesn't include sensitive models if user has chose to hide sensitive content" do
      member.update sensitive_content_handling: "hide"
      expect(scope.resolve).not_to include model
    end
  end
end
