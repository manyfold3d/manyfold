require "rails_helper"

RSpec.describe User do
  it_behaves_like "Follower"
  it_behaves_like "Caber::Subject"

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

  it "gets member role by default" do
    u = create(:user)
    expect(u).to have_role(:member)
  end

  context "with omniauth" do
    let(:auth_data) do
      OpenStruct.new({
        provider: "openid_connect",
        uid: "auth|123456789",
        info: OpenStruct.new({
          email: "test@example.com",
          preferred_username: "username",
          nickname: "nick"
        })
      })
    end

    it "can create a valid user from auth data" do
      expect(described_class.from_omniauth(auth_data)).to be_valid
    end

    it "stores auth provider" do
      user = described_class.from_omniauth(auth_data)
      expect(user.auth_provider).to eq "openid_connect"
    end

    it "stores auth uid" do
      user = described_class.from_omniauth(auth_data)
      expect(user.auth_uid).to eq "auth|123456789"
    end

    it "stores email" do
      user = described_class.from_omniauth(auth_data)
      expect(user.email).to eq "test@example.com"
    end

    it "stores username" do
      user = described_class.from_omniauth(auth_data)
      expect(user.username).to eq "username"
    end

    it "stores nickname as username if preferred username not available" do
      auth_data.info.preferred_username = nil
      user = described_class.from_omniauth(auth_data)
      expect(user.username).to eq "nick"
    end

    it "stores email username as username if preferred username and nickname not available" do
      auth_data.info.preferred_username = nil
      auth_data.info.nickname = nil
      user = described_class.from_omniauth(auth_data)
      expect(user.username).to eq "test"
    end

    it "matches an existing user with identical auth details" do
      user = create(:user, auth_provider: "openid_connect", auth_uid: "auth|123456789")
      expect(described_class.from_omniauth(auth_data)).to eq user
    end

    it "matches an existing user with matching email" do
      user = create(:user, email: "test@example.com")
      expect(described_class.from_omniauth(auth_data)).to eq user
    end

    it "deconflicts a user with matching username by using one of the other options" do
      create(:user, username: "username")
      new_user = described_class.from_omniauth(auth_data)
      expect(new_user.username).to eq "nick"
    end
  end
end
