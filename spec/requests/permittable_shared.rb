shared_examples "Permittable" do |object_class|
  context "when setting permissions" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:symbol) { object_class.to_s.underscore.to_sym }
    let(:caber_object) { create(symbol) }
    let(:path) { symbol.to_s.pluralize }
    let(:owner) { create(:user) }
    let(:editor) { create(:user) }
    let(:object) { create(symbol, owner: owner) }

    before do
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

      it "updates permissions using nested attributes" do
        expect {
          put "/#{path}/#{object.to_param}", params: {symbol => {caber_relations_attributes: {"0" => {subject: "role::public", permission: "view"}}}}
        }.to change(object, :public?).from(false).to(true)
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
