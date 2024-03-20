require "rails_helper"

RSpec.describe Role do
  let(:user) { create(:user) }

  it "can be given to a user" do
    user.add_role :administrator
    expect(user.is_administrator?).to be true
  end
end
