shared_examples "ApplicationPolicy" do
  subject(:policy) { described_class }

  let(:member) { create(:user) }
  let(:object) { create(target_class.to_s.underscore.to_sym) }

  permissions :index?, :show? do
    it "allows users with member role by default" do
      expect(policy).to permit(member, object)
    end

    it "falls back to member role if ReBAC isn't available on the record" do
      problem = create(:problem)
      expect(policy).to permit(member, problem)
    end

    context "when default member role access is removed" do
      before do
        object.revoke_permission("view", Role.find_by(name: :member))
      end

      it "denies users without individual view permission" do
        expect(policy).not_to permit(member, object)
      end

      it "allows users with individual view permission" do
        object.grant_permission_to "view", member
        expect(policy).to permit(member, object)
      end
    end

    context "with an unknown user" do
      it "denies access if public view permission isn't set" do
        expect(policy).not_to permit(nil, object)
      end

      it "allows access if public view permission is set" do
        object.grant_permission_to "view", nil
        expect(policy).to permit(nil, object)
      end
    end
  end

  permissions :create?, :new? do
    let(:contributor) { create(:contributor) }

    it "allows users with contributor role by default" do
      expect(policy).to permit(contributor)
    end

    it "denies users with member role by default" do
      expect(policy).not_to permit(member)
    end

    it "denies unknown users" do
      expect(policy).not_to permit(nil)
    end
  end

  permissions :edit?, :update?, :destroy? do
    let(:moderator) { create(:moderator) }
    let(:contributor) { create(:contributor) }

    it "allows all users with moderator role" do
      expect(policy).to permit(moderator, object)
    end

    it "denies users with contributor role" do
      expect(policy).not_to permit(contributor, object)
    end

    it "allows users with granted edit permission" do
      object.grant_permission_to "edit", member
      expect(policy).to permit(member, object)
    end

    it "allows users with granted owner permission" do
      object.grant_permission_to "own", member
      expect(policy).to permit(member, object)
    end

    it "denies unknown users on public objects" do
      object.grant_permission_to "view", nil
      expect(policy).not_to permit(nil, object)
    end
  end
end
