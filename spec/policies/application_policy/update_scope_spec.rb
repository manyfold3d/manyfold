require "rails_helper"

describe ApplicationPolicy::UpdateScope do
  subject(:scope) { described_class.new(member, item.class) }

  let(:item) { create(:model) }
  let(:member) { create(:user) }

  it "includes editable item in scope" do
    item.grant_permission_to("edit", member)
    expect(scope.resolve).to include(item)
  end

  it "excludes non-editable item from scope" do
    expect(scope.resolve).not_to include(item)
  end
end
