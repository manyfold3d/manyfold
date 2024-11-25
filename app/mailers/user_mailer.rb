class UserMailer < ApplicationMailer
  def account_approved
    # i18n-tasks-use t('user_mailer.account_approved.subject')
    @user = params[:user]
    mail to: @user.email
  end
end
