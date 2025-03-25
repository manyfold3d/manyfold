require "rails_helper"

RSpec.describe ModeratorMailer do
  let(:moderator) { create(:moderator) }

  describe "new_report" do
    let(:mail) { described_class.with(moderator: moderator, report: report).new_report }
    let(:report) { create(:report) }

    it "sets correct subject" do
      expect(mail.subject).to eq("New report received")
    end

    it "sends to user" do
      expect(mail.to).to eq([moderator.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("has reported content")
    end

    it "includes a link to the reports list" do
      expect(mail.body.encoded).to match("/settings/reports/")
    end
  end

  describe "new_approval" do
    let(:mail) { described_class.with(moderator: moderator, user: user).new_approval }
    let(:user) { create(:user) }

    it "sets correct subject" do
      expect(mail.subject).to eq("New account needs approval")
    end

    it "sends to user" do
      expect(mail.to).to eq([moderator.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("requires approval")
    end

    it "includes a link to the user settings" do
      expect(mail.body.encoded).to match("/settings/users/")
    end
  end
end
