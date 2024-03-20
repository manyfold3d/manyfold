require "rails_helper"

RSpec.describe Role do
  let(:user) { create(:user) }

  it "can be given to a user" do
    user.add_role :administrator
    expect(user.is_administrator?).to be true
  end

  it "must be from the allowed list" do # rubocop:disable RSpec/MultipleExpectations
    expect { user.add_role :batman }.to raise_error(ActiveRecord::RecordInvalid)
    expect(user.has_role?(:batman)).to be false
  end
end
