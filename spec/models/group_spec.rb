require "rails_helper"

RSpec.describe Group do
  it "must be owned by a user" do
    group = build(:group, user: nil)
    expect(group).not_to be_valid
  end

  it "is in the owning users list of groups" do
    alice = create(:user)
    group = create(:group, user: alice)
    expect(alice.groups).to include(group)
  end

  it "has members (which are users)" do
    alice = create(:user)
    group = create(:group)
    group.members << alice
    expect(group.members).to include alice
  end
end
