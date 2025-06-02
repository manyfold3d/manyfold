require "rails_helper"

describe ApplicationPolicy::Scope do
  subject(:scope) { described_class.new(member, item.class) }

  let(:item) { create(:model) }
  let(:member) { create(:user) }

  it "includes viewable item in scope" do
    expect(scope.resolve).to include(item)
  end

  it "excludes non-viewable item from scope" do
    item.revoke_permission("view", Role.find_by(name: :member))
    expect(scope.resolve).not_to include(item)
  end
end
