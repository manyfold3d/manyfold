class GroupMailer < ApplicationMailer
  def new_member
    # i18n-tasks-use t('group_mailer.new_member.subject')
    @user = params[:notification].recipient
    @group = params[:membership].group
    mail to: @user.email
  end
end
