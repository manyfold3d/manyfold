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

  context "when duplicate roles exist" do
    let!(:user) { create(:user) }
    let!(:moderator) { create(:moderator) } # rubocop:disable RSpec/LetSetup

    before do
      # Rename moderator role to member without validations so we get a duplicate
      described_class.where(name: "member").update_all(name: "moderator") # rubocop:disable Rails/SkipsModelValidations
      user.reload
      user.add_role :member
    end

    it "sets up two roles called moderator" do
      expect(described_class.where(name: "moderator").count).to eq 2
    end

    it "shows that user has one of the moderator roles" do
      expect(user.roles.map(&:name)).to include "moderator"
    end

    it "combines duplicated roles" do
      expect { described_class.merge_duplicates! }.to change(described_class, :count).from(3).to(2)
    end

    it "preserves user's mod role" do
      described_class.merge_duplicates!
      expect(user.is_moderator?).to be true
    end

    it "leaves user with two valid roles" do
      described_class.merge_duplicates!
      expect(user.roles.map(&:name)).to contain_exactly("moderator", "member")
    end

    it "preserves moderator's mod role" do
      described_class.merge_duplicates!
      expect(moderator.is_moderator?).to be true
    end
  end
end
