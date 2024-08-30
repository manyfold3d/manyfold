require "rails_helper"

describe ApplicationPolicy do
  subject(:policy) { described_class }

  let(:viewer) { create(:user) }
  let(:model) { create(:model) }

  permissions :index?, :show? do
    it "allows users with viewer role by default" do
      expect(policy).to permit(viewer, model)
    end

    it "falls back to viewer role if ReBAC isn't available on the record" do
      problem = create(:problem)
      expect(policy).to permit(viewer, problem)
    end

    context "when default viewer role access is removed" do
      before do
        model.revoke_permission("viewer", Role.find_by(name: :viewer))
      end

      it "denies users without individual viewer permission" do
        expect(policy).not_to permit(viewer, model)
      end

      it "allows users with individual viewer permission" do
        model.grant_permission_to "viewer", viewer
        expect(policy).to permit(viewer, model)
      end
    end

    context "with an unknown user" do
      it "denies access if public view permission isn't set" do
        expect(policy).not_to permit(nil, model)
      end

      it "allows access if public view permission is set" do
        model.grant_permission_to "viewer", nil
        expect(policy).to permit(nil, model)
      end
    end
  end

  permissions :create?, :new? do
    let(:contributor) { create(:contributor) }

    it "allows users with contributor role by default" do
      expect(policy).to permit(contributor, model)
    end

    it "denies users with viewer role by default" do
      expect(policy).not_to permit(viewer, model)
    end
  end

  permissions :edit?, :update?, :destroy? do
    let(:editor) { create(:editor) }
    let(:contributor) { create(:contributor) }

    it "allows all users with editor role" do
      expect(policy).to permit(editor, model)
    end

    it "denies users with contributor role" do
      expect(policy).not_to permit(contributor, model)
    end

    it "allows users with granted edit permission" do
      model.grant_permission_to "editor", viewer
      expect(policy).to permit(viewer, model)
    end

    it "allows users with granted owner permission" do
      model.grant_permission_to "owner", viewer
      expect(policy).to permit(viewer, model)
    end
  end
end
