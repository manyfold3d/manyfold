require "rails_helper"

RSpec.describe GroupMailer do
  describe "sending a notification to a new group member" do
    let(:group) { create(:group, members: [user]) }
    let(:notification) { instance_double(Noticed::Notification, recipient: user) }
    let(:mail) { described_class.with(notification: notification, membership: group.memberships.last).new_member }

    before do
      allow(SiteSettings).to receive(:site_name).and_return("Manyfold Testing")
    end

    describe "existing member added to group" do
      let(:user) { create(:user) }

      it "sets correct subject" do
        expect(mail.subject).to eq("You've been added to a group on Manyfold Testing")
      end

      it "sends to user" do
        expect(mail.to).to eq([user.email])
      end

      it "renders the body for existing users" do
        expect(mail.body.encoded).to match("You've been added to")
      end

      it "includes group name" do
        expect(mail.body.encoded).to match(group.name)
      end
    end

    describe "new member invited to group by email" do
      let(:user) do
        attrs = attributes_for(:user)
        User.invite!(email: attrs[:email], skip_invitation: true)
      end

      it "sets invitation delivery timestamp" do
        expect { mail.subject }.to change { user.reload.invitation_sent_at }.from(nil)
      end

      it "sets correct subject" do
        expect(mail.subject).to eq("Claim your models on Manyfold Testing")
      end

      it "sends to user" do
        expect(mail.to).to eq([user.email])
      end

      it "includes invitation URL" do
        expect(mail.body.encoded).to match(/http:\/\/example\.com:3214\/users\/invitation\/accept\?invitation_token=#{user.raw_invitation_token}/)
      end

      it "includes invitation expiry" do
        expect(mail.body.encoded).to match("This invitation is valid until")
      end

      it "includes invitation ignore message" do
        expect(mail.body.encoded).to match("ignore this email")
      end

      it "includes group name" do
        expect(mail.body.encoded).to match(group.name)
      end

      it "includes creator name" do
        expect(mail.body.encoded).to match(group.creator.name)
      end
    end
  end
end
