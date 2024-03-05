require "rails_helper"

RSpec.describe User do
  it "requires a username" do
    expect(build(:user, username: nil)).not_to be_valid
  end

  it "doesn't allow single-character usernames" do
    expect(build(:user, username: "a")).not_to be_valid
  end

  it "doesn't allow two-character usernames" do
    expect(build(:user, username: "ab")).not_to be_valid
  end

  it "allow three-character usernames" do
    expect(build(:user, username: "abc")).to be_valid
  end

  it "allows numbers in usernames" do
    expect(build(:user, username: "3jane")).to be_valid
  end

  it "allows non-ASCII usernames" do
    expect(build(:user, username: "إعلانات")).to be_valid
  end

  it "doesn't allows punctuation in usernames" do
    expect(build(:user, username: "user-name")).not_to be_valid
  end

  it "doesn't allow usernames that differ by case" do
    create(:user, username: "userName")
    expect(build(:user, username: "USERNAME")).not_to be_valid
  end
end
