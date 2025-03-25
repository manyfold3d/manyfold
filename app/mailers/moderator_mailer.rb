class ModeratorMailer < ApplicationMailer
  def new_report
    # i18n-tasks-use t('moderator_mailer.new_report.subject')
    @report = params[:report]
    mail bcc: moderator_addresses
  end

  def new_approval
    # i18n-tasks-use t('moderator_mailer.new_approval.subject')
    @user = params[:user]
    mail bcc: moderator_addresses
  end

  private

  def moderator_addresses
    User.with_any_role(:moderator, :administrator).pluck(:email)
  end
end
