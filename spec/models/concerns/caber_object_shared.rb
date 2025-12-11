shared_examples "Caber::Object" do
  let(:caber_object) { create(described_class.to_s.underscore.to_sym) }
  let!(:admin) { create(:admin) }
  let(:contributor) { create(:contributor) }
  let(:member) { create(:user) }

  it "has caber relations" do
    expect(caber_object.class).to respond_to :can_grant_permissions_to
  end

  it "is created with a default owner" do
    create(described_class.to_s.underscore.to_sym)
    expect(caber_object.grants_permission_to?("own", admin)).to be true
  end

  it "can be given an explicit owner at creation" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    object = create(described_class.to_s.underscore.to_sym, owner: contributor)
    expect(object.grants_permission_to?("own", contributor)).to be true
    expect(object.grants_permission_to?("own", admin)).to be false
  end

  context "when assigning permissions at creation" do
    context "with public preset" do
      let(:object) {
        options = {permission_preset: "public"}
        options[:creator] = create(:creator) if described_class.column_names.include?("creator_id")
        create(described_class.to_s.underscore.to_sym, options)
      }

      it "grants view permission to public role" do
        expect(object.grants_permission_to?("view", nil)).to be true
      end

      it "does not grant public update permission" do
        expect(object.grants_permission_to?("update", nil)).to be false
      end
    end

    context "with member preset" do
      let(:object) { create(described_class.to_s.underscore.to_sym, permission_preset: "member") }

      it "grants view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be true
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end

    context "with private preset" do
      let(:object) { create(described_class.to_s.underscore.to_sym, permission_preset: "private") }

      it "does not grant view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be false
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end

    context "with default permissions set to public" do
      before do
        allow(SiteSettings).to receive(:default_viewer_role).and_return(:public)
      end

      let(:object) { create(described_class.to_s.underscore.to_sym) }

      it "grants view permission to member role" do
        expect(object.grants_permission_to?("view", nil)).to be true
      end

      it "does not grant public update permission" do
        expect(object.grants_permission_to?("update", nil)).to be false
      end
    end

    context "with default permissions set to member-visible" do
      before do
        allow(SiteSettings).to receive(:default_viewer_role).and_return(:member)
      end

      let(:object) { create(described_class.to_s.underscore.to_sym) }

      it "grants view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be true
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end

    context "with default permissions set to private" do
      before do
        allow(SiteSettings).to receive(:default_viewer_role).and_return(:private)
      end

      let(:object) { create(described_class.to_s.underscore.to_sym) }

      it "does not grant view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be false
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end
  end

  context "when assigning permissions presets during update" do
    let(:object) {
      options = {owner: contributor}
      options[:creator] = create(:creator) if described_class.column_names.include?("creator_id")
      create(described_class.to_s.underscore.to_sym, options)
    }

    context "with public preset" do
      before do
        object.update!(permission_preset: "public")
      end

      it "grants view permission to public role" do
        expect(object.grants_permission_to?("view", nil)).to be true
      end

      it "does not grant public update permission" do
        expect(object.grants_permission_to?("update", nil)).to be false
      end
    end

    context "with member preset" do
      before do
        object.update!(permission_preset: "member")
      end

      it "grants view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be true
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end

    context "with private preset" do
      before do
        object.update!(permission_preset: "private")
      end

      it "does not grant view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be false
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end
    end

    context "with both preset and explicit permissions" do
      before do
        object.update!(permission_preset: "member", caber_relations_attributes: [{permission: "view", subject: nil}])
      end

      it "grants view permission to member role" do
        expect(object.grants_permission_to?("view", Role.find_by!(name: "member"))).to be true
      end

      it "does not grant public view permission" do
        expect(object.grants_permission_to?("view", nil)).to be false
      end

      it "does not wipe owner relation" do
        expect(object.grants_permission_to?("own", contributor)).to be true
      end
    end
  end

  context "when working out matching preset" do
    let(:object) { create(described_class.to_s.underscore.to_sym) }

    before do
      allow(SiteSettings).to receive(:default_viewer_role).and_return(:private)
      object.caber_relations.destroy_all
      object.grant_permission_to("own", SiteSettings.default_user)
    end

    it "is private if there is only one owner and no other permissions" do
      expect(object.matching_permission_preset).to eq "private"
    end

    it "is public if there is a public view permission, an owner, and nothing else" do
      object.update(creator: create(:creator)) if described_class.column_names.include?("creator_id")
      object.grant_permission_to "view", nil
      expect(object.reload.matching_permission_preset).to eq "public"
    end

    it "is member if there is a member view permission, an owner, and nothing else" do
      object.grant_permission_to "view", Role.find_by(name: "member")
      expect(object.reload.matching_permission_preset).to eq "member"
    end

    it "is advanced (empty) in any other case" do
      object.grant_permission_to "edit", contributor
      expect(object.reload.matching_permission_preset).to eq ""
    end
  end

  context "when managing group permissions" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:object) { create(described_class.to_s.underscore.to_sym) }

    before do
      group.members << user
      allow(SiteSettings).to receive(:default_viewer_role).and_return(:private)
      object.caber_relations.destroy_all
      object.grant_permission_to("own", SiteSettings.default_user)
    end

    it "group does not have view permission by default" do
      expect(object.grants_permission_to?("view", group)).to be false
    end

    it "user does not have view permission by default" do # rubocop:disable RSpec/MultipleExpectations
      policy = Pundit::PolicyFinder.new(object).policy
      scope = Pundit::PolicyFinder.new(object).scope
      expect(policy.new(user, object).show?).to be false
      expect(scope.new(user, described_class).resolve).not_to include object
    end

    it "can assign a permission to a group" do
      object.grant_permission_to "view", group
      expect(object.grants_permission_to?("view", group)).to be true
    end

    it "delegates user permission to the group" do # rubocop:disable RSpec/MultipleExpectations
      object.grant_permission_to "view", group
      policy = Pundit::PolicyFinder.new(object).policy
      scope = Pundit::PolicyFinder.new(object).scope
      expect(policy.new(user, object).show?).to be true
      expect(scope.new(user, described_class).resolve).to include object
    end
  end
end
