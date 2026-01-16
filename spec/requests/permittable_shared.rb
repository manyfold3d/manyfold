shared_examples "Permittable" do |object_class|
  context "when setting permissions" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:symbol) { object_class.to_s.underscore.to_sym }
    let(:caber_object) { create(symbol) }
    let(:path) { symbol.to_s.pluralize }
    let(:owner) { create(:user) }
    let(:editor) { create(:user) }
    let(:object) { create(symbol, owner: owner) }

    before do
      allow(SiteSettings).to receive(:default_viewer_role).and_return(:private)
      object.try(:license=, "MIT")
      object.try(:creator=, create(:creator))
      object.grant_permission_to("edit", editor)
      object.save!
    end

    context "when logged in as owner" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      before do
        sign_in owner
      end

      it "updates permissions using preset" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {permission_preset: "public"}}
        }.to change(object, :public?).from(false).to(true)
      end

      it "grants permissions to public role" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: "role::public", permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", nil) }.from(false).to(true)
      end

      it "grants permissions to member role" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: "role::member", permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", Role.find_by!(name: "member")) }.from(false).to(true)
      end

      it "grants permissions to usernames" do # rubocop:disable RSpec/MultipleExpectations
        u = create(:user)
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: u.username, permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", u) }.from(false).to(true)
        expect(object.reload).not_to be_public
      end

      it "grants permissions to users by email" do # rubocop:disable RSpec/MultipleExpectations
        u = create(:user)
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: u.email, permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", u) }.from(false).to(true)
        expect(object.reload).not_to be_public
      end

      it "grants permissions to users by fediverse address" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        allow(SiteSettings).to receive(:federation_enabled?).and_return(true)
        u = create(:user)
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: u.federails_actor.at_address, permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", u) }.from(false).to(true)
        expect(object.reload).not_to be_public
      end

      it "grants permissions to groups" do # rubocop:disable RSpec/MultipleExpectations
        group = create(:group)
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: group.typed_id, permission: "view"}}}}
        }.to change { object.grants_permission_to?("view", group) }.from(false).to(true)
        expect(object.reload).not_to be_public
      end
    end

    context "when logged in as editor" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      before do
        sign_in editor
      end

      it "doesn't update permissions using preset" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {permission_preset: "public"}}
        }.not_to change(object, :public?)
      end

      it "doesn't update permissions using nested attributes" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: "role::public", permission: "view"}}}}
        }.not_to change(object, :public?)
      end
    end
  end
end
