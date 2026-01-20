class GroupMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.group_mailer.new_member.subject
  #
  def new_member
    @user = params[:notification].recipient
    @group = params[:membership].group
    mail to: @user.email
  end
end
