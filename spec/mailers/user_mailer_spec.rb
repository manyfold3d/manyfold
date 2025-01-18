require "rails_helper"

RSpec.describe UserMailer do
  describe "account_approved" do
    let(:user) { create(:user) }
    let(:mail) { described_class.with(user: user).account_approved }

    it "sets correct subject" do
      expect(mail.subject).to eq("Account approved")
    end

    it "sends to user" do
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "test_email" do
    let(:user) { create(:user) }
    let(:mail) { described_class.with(user: user).test_email}

    it "sets correct subject" do
      expect(mail.subject).to eq("Test email")
    end

    it "sends to user" do
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Test email")
    end
  end
end
