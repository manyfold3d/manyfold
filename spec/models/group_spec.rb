require "rails_helper"

RSpec.describe Group do
  it_behaves_like "Caber::Subject"

  it "must be owned by a creator" do
    group = build(:group, creator: nil)
    expect(group).not_to be_valid
  end

  it "is in the owning creator's list of groups" do
    alice = create(:creator)
    group = create(:group, creator: alice)
    expect(alice.groups).to include(group)
  end

  it "has members (which are users)" do
    alice = create(:user)
    group = create(:group)
    group.members << alice
    expect(group.members).to include alice
  end
end
