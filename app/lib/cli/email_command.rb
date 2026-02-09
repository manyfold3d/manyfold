require "thor"

module Cli
  class EmailCommand < Thor
    COMMAND = "email"
    DESCRIPTION = "test email"

    desc "test", "sends test email"
    def test
      UserMailer.with(user: User.find(1)).account_approved.deliver_now # rubocop:disable Pundit/UsePolicyScope
    end
  end
end
