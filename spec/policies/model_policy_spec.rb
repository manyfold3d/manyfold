require "rails_helper"

describe ModelPolicy do
  subject(:policy) { described_class }

  let(:member) { create(:user) }
  let(:moderator) { create(:moderator) }
  let(:model) { create(:model) }
  let(:nested) { create(:model) }

  permissions :destroy? do
    it "denies deletion to users with member role" do
      expect(policy).not_to permit(member, model)
    end

    it "allows deletion by users with moderator role" do
      expect(policy).to permit(moderator, model)
    end

    it "denies deletion for models that contain others" do
      create(:model, library: model.library, path: model.path + "/nested")
      expect(policy).not_to permit(moderator, model.reload)
    end
  end

  permissions :show? do
    context "with sensitive content" do
      before do
        model.update(sensitive: true)
      end

      it "allows by default" do
        expect(policy).to permit(member, model)
      end

      it "allows public items with no user" do
        model.grant_permission_to "view", nil
        expect(policy).to permit(nil, model)
      end

      it "denies if user has chosen to hide sensitive" do
        member.update sensitive_content_handling: "hide"
        expect(policy).not_to permit(member, model)
      end
    end
  end
end
