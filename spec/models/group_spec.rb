require "rails_helper"

RSpec.describe Group do
  it "must be owned by a user" do
    group = build(:group, user: nil)
    expect(group).not_to be_valid
  end
end
