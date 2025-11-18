require "rails_helper"

describe ModelPolicy do
  subject(:policy) { described_class }

  let(:target_class) { Model }

  let(:nested) { create(:model) }
  let(:model) { create(:model) }
  let(:moderator) { create(:moderator) }
  let(:member) { create(:user) }

  it_behaves_like "ApplicationPolicy"

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

    context "with preview granted" do
      it "allows preview items with no user" do
        model.grant_permission_to "preview", nil
        expect(policy).to permit(nil, model)
      end

      it "allows user with standard permissions to preview" do
        model.revoke_all_permissions(Role.find_by!(name: :member))
        model.grant_permission_to "preview", nil
        expect(policy).to permit(member, model)
      end

      it "allows user with specific preview grant" do
        model.revoke_all_permissions(Role.find_by!(name: :member))
        model.grant_permission_to "preview", member
        expect(policy).to permit(member, model)
      end
    end
  end

  permissions :download? do
    context "with preview granted" do
      it "doesn't allow public download" do
        model.grant_permission_to "preview", nil
        expect(policy).not_to permit(nil, model)
      end

      it "doesn't allow user with standard permissions to download" do
        model.revoke_all_permissions(Role.find_by!(name: :member))
        model.grant_permission_to "preview", nil
        expect(policy).not_to permit(member, model)
      end

      it "doesn't allow user with specific preview grant to download" do
        model.revoke_all_permissions(Role.find_by!(name: :member))
        model.grant_permission_to "preview", member
        expect(policy).not_to permit(member, model)
      end

      it "allows user with proper view grant to download" do
        model.revoke_all_permissions(Role.find_by!(name: :member))
        model.grant_permission_to "view", member
        expect(policy).to permit(member, model)
      end
    end
  end
end
