# To deliver this notification:
#
# NewGroupMembershipNotifier.with(record: @post, message: "New post").deliver(User.all)

class NewGroupMemberNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "GroupMailer"
    config.method = "new_member"
  end
end
