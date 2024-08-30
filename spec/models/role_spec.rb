require "rails_helper"
RSpec.describe Role do
  let(:user) { create(:user) }

  it_behaves_like "Caber::Subject"

  it "can be given to a user" do
    user.add_role :administrator
    expect(user.has_role?(:administrator)).to be true
  end

  it "must be from the allowed list" do # rubocop:disable RSpec/MultipleExpectations
    expect { user.add_role :batman }.to raise_error(ActiveRecord::RecordInvalid)
    expect(user.has_role?(:batman)).to be false
  end

  context "when administrator" do
    let(:admin) { create(:admin) }

    it "has administrator permission" do
      expect(admin.is_administrator?).to be true
    end

    it "inherits moderator permission" do
      expect(admin.is_moderator?).to be true
    end

    it "inherits contributor permission" do
      expect(admin.is_contributor?).to be true
    end

    it "inherits member permission" do
      expect(admin.is_member?).to be true
    end
  end

  context "when moderator" do
    let(:moderator) { create(:moderator) }

    it "does not have administrator permission" do
      expect(moderator.is_administrator?).to be false
    end

    it "has moderator permission" do
      expect(moderator.is_moderator?).to be true
    end

    it "inherits contributor permission" do
      expect(moderator.is_contributor?).to be true
    end

    it "inherits member permission" do
      expect(moderator.is_member?).to be true
    end
  end

  context "when contributor" do
    let(:contributor) { create(:contributor) }

    it "does not have administrator permission" do
      expect(contributor.is_administrator?).to be false
    end

    it "does not have moderator permission" do
      expect(contributor.is_moderator?).to be false
    end

    it "has contributor permission" do
      expect(contributor.is_contributor?).to be true
    end

    it "inherits member permission" do
      expect(contributor.is_member?).to be true
    end
  end

  context "when member" do
    let(:member) { create(:user) }

    it "does not have administrator permission" do
      expect(member.is_administrator?).to be false
    end

    it "does not have moderator permission" do
      expect(member.is_moderator?).to be false
    end

    it "does not have contributor permission" do
      expect(member.is_contributor?).to be false
    end

    it "has member permission" do
      expect(member.is_member?).to be true
    end
  end
end
